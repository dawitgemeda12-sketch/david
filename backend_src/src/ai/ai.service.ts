import { BadRequestException, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Backend-only AI Stylist proxy.
 *
 * SECURITY / ARCHITECTURE NOTES:
 *  - The Anthropic API key NEVER leaves this service. It is read from
 *    process.env.ANTHROPIC_API_KEY at call time (never written to any
 *    response, log line, or the .env file committed to the repo — see
 *    backend/.env comment). Flutter never sees a key of any kind.
 *  - The backend controls the ENTIRE prompt: system instructions plus
 *    a structured summary of the user's REAL wardrobe (their actual
 *    WardrobeItem rows) is injected server-side before every call. The
 *    client can only ever send free-text chat content, never a prompt
 *    override.
 *  - The system prompt explicitly instructs the model to prefer items
 *    the user already owns over suggesting a purchase, in line with
 *    "Wear What You Own. Wear It Better." — this is a real constraint
 *    encoded in the prompt, not just a marketing claim.
 *  - Every AiMessage persisted to Postgres stores only role/content and
 *    (optionally) which real wardrobe item ids the reply referenced —
 *    never the API key, never a fabricated item id.
 *  - Basic per-user rate limiting beyond the global Throttler: a hard
 *    cap of MAX_MESSAGES_PER_WINDOW messages within RATE_WINDOW_MS,
 *    computed from real AiMessage rows (role='user'), to protect the
 *    (metered) upstream AI provider from abuse.
 */
@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private anthropic: any | null = null;

  private static readonly MAX_MESSAGES_PER_WINDOW = 20;
  private static readonly RATE_WINDOW_MS = 60 * 60 * 1000; // 1 hour

  constructor(private readonly prisma: PrismaService) {}

  private async getClient() {
    if (this.anthropic) return this.anthropic;
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      // Fail loudly but safely — never silently mock a response as if
      // it came from a real model.
      throw new BadRequestException(
        'AI stylist is not configured on the server (missing ANTHROPIC_API_KEY). Contact the administrator.',
      );
    }
    const { default: Anthropic } = await import('@anthropic-ai/sdk');
    this.anthropic = new Anthropic({ apiKey });
    return this.anthropic;
  }

  async listConversations(userId: string) {
    return this.prisma.aiConversation.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      select: { id: true, title: true, createdAt: true, updatedAt: true },
    });
  }

  async getConversation(userId: string, conversationId: string) {
    const convo = await this.prisma.aiConversation.findFirst({
      where: { id: conversationId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!convo) throw new NotFoundException('Conversation not found.');
    if (convo.userId !== userId) throw new ForbiddenException('You do not have access to this conversation.');
    return convo;
  }

  async sendMessage(userId: string, message: string, conversationId?: string) {
    await this.assertNotRateLimited(userId);

    let convo = conversationId
      ? await this.prisma.aiConversation.findFirst({ where: { id: conversationId } })
      : null;
    if (conversationId && !convo) throw new NotFoundException('Conversation not found.');
    if (convo && convo.userId !== userId) {
      throw new ForbiddenException('You do not have access to this conversation.');
    }
    if (!convo) {
      convo = await this.prisma.aiConversation.create({
        data: { userId, title: message.slice(0, 60) },
      });
    }

    // Persist the user's message first (append-only history).
    await this.prisma.aiMessage.create({
      data: { conversationId: convo.id, role: 'user', content: message },
    });

    const priorMessages = await this.prisma.aiMessage.findMany({
      where: { conversationId: convo.id },
      orderBy: { createdAt: 'asc' },
      take: 20, // bounded context window — never load unlimited history
    });

    const wardrobeContext = await this.buildWardrobeContext(userId);
    const systemPrompt = this.buildSystemPrompt(wardrobeContext);

    const client = await this.getClient();
    const providerModel = 'claude-haiku-4-5';

    let replyText: string;
    try {
      const response = await client.messages.create({
        model: providerModel,
        max_tokens: 600,
        system: systemPrompt,
        messages: priorMessages.map((m) => ({
          role: m.role === 'assistant' ? 'assistant' : 'user',
          content: m.content,
        })),
      });
      replyText = response.content
        .filter((block: any) => block.type === 'text')
        .map((block: any) => block.text)
        .join('\n')
        .trim();
      if (!replyText) replyText = "I couldn't come up with a suggestion just now — try rephrasing your question.";
    } catch (err) {
      this.logger.error(`AI provider call failed: ${(err as Error).message}`);
      throw new BadRequestException('The AI stylist is temporarily unavailable. Please try again shortly.');
    }

    // Only reference REAL wardrobe item ids that were actually part of
    // the context we sent — never invent references.
    const referencedIds = wardrobeContext.items
      .filter((item) => replyText.toLowerCase().includes(item.name.toLowerCase()))
      .map((item) => item.id);

    const assistantMessage = await this.prisma.aiMessage.create({
      data: {
        conversationId: convo.id,
        role: 'assistant',
        content: replyText,
        referencedWardrobeItemIds: referencedIds,
        providerModel,
      },
    });

    await this.prisma.aiConversation.update({
      where: { id: convo.id },
      data: { updatedAt: new Date() },
    });

    return { conversationId: convo.id, message: assistantMessage };
  }

  private async buildWardrobeContext(userId: string) {
    const items = await this.prisma.wardrobeItem.findMany({
      where: { userId, deletedAt: null, isArchived: false },
      select: { id: true, name: true, categoryName: true, color: true, style: true, formality: true, wearCount: true },
      take: 100, // bounded — never dump an unbounded wardrobe into every prompt
      orderBy: { updatedAt: 'desc' },
    });
    return { items };
  }

  private buildSystemPrompt(wardrobeContext: { items: any[] }): string {
    const wardrobeSummary =
      wardrobeContext.items.length === 0
        ? 'The user has not logged any wardrobe items yet.'
        : wardrobeContext.items
            .map((i) => `- ${i.name} (${i.categoryName}${i.color ? `, ${i.color}` : ''}${i.style ? `, ${i.style}` : ''})`)
            .join('\n');

    return [
      'You are the Stylish AI Stylist, part of "Stylish" — Africa\'s most trusted personal fashion platform, launching in Addis Ababa, Ethiopia. Your tagline: "Wear What You Own. Wear It Better."',
      'Ground rules:',
      '1. ALWAYS reason from the user\'s REAL wardrobe listed below first. Recommend outfit combinations using items they already own whenever a suitable combination exists.',
      '2. Only suggest buying something new if there is a genuine gap the current wardrobe cannot cover for the stated occasion — and even then, phrase it as an optional idea, never a hard sell.',
      '3. Never invent specific retailer names, prices, or product links — you do not have that information.',
      '4. Keep responses concise, warm, and practical, tailored to Ethiopian climate and culture where relevant (e.g. Addis Ababa\'s mild, temperate weather).',
      '5. Currency is ETB (Ethiopian Birr) if prices are ever discussed.',
      '',
      "User's current wardrobe (owned items):",
      wardrobeSummary,
    ].join('\n');
  }

  private async assertNotRateLimited(userId: string) {
    const since = new Date(Date.now() - AiService.RATE_WINDOW_MS);
    const recentUserMessages = await this.prisma.aiMessage.count({
      where: {
        role: 'user',
        createdAt: { gte: since },
        conversation: { userId },
      },
    });
    if (recentUserMessages >= AiService.MAX_MESSAGES_PER_WINDOW) {
      throw new BadRequestException('You have reached the AI stylist usage limit for this hour. Please try again later.');
    }
  }
}
