import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CreateOutfitDto } from './create-outfit.dto';

// items are updated via a dedicated method (replaceItems) rather than
// the generic PATCH body, to keep ownership validation simple and explicit.
export class UpdateOutfitDto extends PartialType(OmitType(CreateOutfitDto, ['items'] as const)) {}
