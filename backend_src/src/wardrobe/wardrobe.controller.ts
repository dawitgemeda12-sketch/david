import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import * as fs from 'fs';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { WardrobeService } from './wardrobe.service';
import { CreateWardrobeItemDto } from './dto/create-wardrobe-item.dto';
import { UpdateWardrobeItemDto } from './dto/update-wardrobe-item.dto';
import { QueryWardrobeDto } from './dto/query-wardrobe.dto';

// Only real image mime types are accepted for wardrobe photos. Anything
// else (e.g. application/octet-stream, video, pdf) is rejected up front
// rather than silently stored — a genuine input-validation control.
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX_UPLOAD_BYTES = 8 * 1024 * 1024; // 8MB

// Local-disk storage driver for development (see STORAGE_DRIVER=local
// in .env). Production is expected to swap this for an S3-compatible
// object storage client behind the same WardrobeService.addImage() call
// — the controller only ever hands the service a storageKey + metadata,
// never raw bytes, so the storage backend can change without touching
// the ownership/DB logic in the service.
const uploadRoot = process.env.STORAGE_LOCAL_PATH || './uploads';
if (!fs.existsSync(uploadRoot)) fs.mkdirSync(uploadRoot, { recursive: true });

@UseGuards(JwtAuthGuard)
@Controller('wardrobe')
export class WardrobeController {
  constructor(private readonly wardrobeService: WardrobeService) {}

  @Get()
  list(@CurrentUser('id') userId: string, @Query() query: QueryWardrobeDto) {
    return this.wardrobeService.list(userId, query);
  }

  @Get('stats/categories')
  categoryCounts(@CurrentUser('id') userId: string) {
    return this.wardrobeService.categoryCounts(userId);
  }

  @Get(':id')
  findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.wardrobeService.findOneOwned(userId, id);
  }

  @Post()
  create(@CurrentUser('id') userId: string, @Body() dto: CreateWardrobeItemDto) {
    return this.wardrobeService.create(userId, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateWardrobeItemDto,
  ) {
    return this.wardrobeService.update(userId, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.wardrobeService.remove(userId, id);
  }

  @Post(':id/favorite')
  toggleFavorite(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.wardrobeService.toggleFavorite(userId, id);
  }

  @Post(':id/archive')
  toggleArchive(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.wardrobeService.toggleArchive(userId, id);
  }

  @Post(':id/worn')
  markWorn(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.wardrobeService.markWorn(userId, id);
  }

  @Post(':id/images')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: uploadRoot,
        filename: (_req, file, cb) => {
          // Secure, unguessable filename — never trust the client's
          // original filename for path construction.
          const safeExt = extname(file.originalname).toLowerCase();
          cb(null, `${randomUUID()}${safeExt}`);
        },
      }),
      limits: { fileSize: MAX_UPLOAD_BYTES },
      fileFilter: (_req, file, cb) => {
        if (!ALLOWED_MIME.has(file.mimetype)) {
          return cb(new BadRequestException('Only JPEG, PNG, or WEBP images are allowed.'), false);
        }
        cb(null, true);
      },
    }),
  )
  async addImage(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No image file provided.');
    // storageKey is a relative reference, never a public URL — access is
    // mediated through the API, not a directly browsable static path.
    const storageKey = join('wardrobe', file.filename);
    return this.wardrobeService.addImage(userId, id, {
      storageKey,
      originalMime: file.mimetype,
      sizeBytes: file.size,
    });
  }
}
