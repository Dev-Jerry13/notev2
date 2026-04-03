// lib/models/note_model.g.dart
// GENERATED CODE - Manual adaptation for Hive

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteColorAdapter extends TypeAdapter<NoteColor> {
  @override
  final int typeId = 2;

  @override
  NoteColor read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return NoteColor.none;
      case 1: return NoteColor.yellow;
      case 2: return NoteColor.blue;
      case 3: return NoteColor.green;
      case 4: return NoteColor.pink;
      case 5: return NoteColor.purple;
      case 6: return NoteColor.orange;
      default: return NoteColor.none;
    }
  }

  @override
  void write(BinaryWriter writer, NoteColor obj) {
    writer.writeByte(obj.index);
  }
}

class NoteAttachmentAdapter extends TypeAdapter<NoteAttachment> {
  @override
  final int typeId = 1;

  @override
  NoteAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteAttachment(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      type: fields[3] as String,
      sizeBytes: fields[4] as int,
      addedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoteAttachment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.path)
      ..writeByte(3)..write(obj.type)
      ..writeByte(4)..write(obj.sizeBytes)
      ..writeByte(5)..write(obj.addedAt);
  }
}

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      richContent: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      isPinned: fields[6] as bool,
      isLocked: fields[7] as bool,
      lockHash: fields[8] as String?,
      folderId: fields[9] as String?,
      tags: (fields[10] as List).cast<String>(),
      attachments: (fields[11] as List).cast<NoteAttachment>(),
      color: fields[12] as NoteColor,
      isArchived: fields[13] as bool,
      isTrashed: fields[14] as bool,
      trashedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.content)
      ..writeByte(3)..write(obj.richContent)
      ..writeByte(4)..write(obj.createdAt)
      ..writeByte(5)..write(obj.updatedAt)
      ..writeByte(6)..write(obj.isPinned)
      ..writeByte(7)..write(obj.isLocked)
      ..writeByte(8)..write(obj.lockHash)
      ..writeByte(9)..write(obj.folderId)
      ..writeByte(10)..write(obj.tags)
      ..writeByte(11)..write(obj.attachments)
      ..writeByte(12)..write(obj.color)
      ..writeByte(13)..write(obj.isArchived)
      ..writeByte(14)..write(obj.isTrashed)
      ..writeByte(15)..write(obj.trashedAt);
  }
}

class FolderModelAdapter extends TypeAdapter<FolderModel> {
  @override
  final int typeId = 3;

  @override
  FolderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FolderModel(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String,
      createdAt: fields[3] as DateTime,
      colorValue: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FolderModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.icon)
      ..writeByte(3)..write(obj.createdAt)
      ..writeByte(4)..write(obj.colorValue);
  }
}
