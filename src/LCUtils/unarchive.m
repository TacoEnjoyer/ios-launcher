#import "src/components/LogUtils.h"
#import "unarchive.h"

#include "archive.h"
#include "archive_entry.h"

CGFloat completedUnitCount = 0;
CGFloat totalUnitCount = 0;

static int copy_data(struct archive* ar, struct archive* aw, NSProgress* progress) {
	int r;
	const void* buff;
	size_t size;
	la_int64_t offset;

	for (;;) {
		r = archive_read_data_block(ar, &buff, &size, &offset);
		if (r == ARCHIVE_EOF)
			return (ARCHIVE_OK);
		if (r < ARCHIVE_OK)
			return (r);
		r = archive_write_data_block(aw, buff, size, offset);
		if (r < ARCHIVE_OK) {
			fprintf(stderr, "%s\n", archive_error_string(aw));
			return (r);
		}
		progress.completedUnitCount += size;
		completedUnitCount += size;
	}
}

CGFloat getProgress() {
	CGFloat progress = ((completedUnitCount / totalUnitCount) * 100);
	if (!(progress >= 0)) {
		return 1;
	} else {
		return progress;
	}
}

int extract(NSString* fileToExtract, NSString* extractionPath, NSProgress* progress) {
	completedUnitCount = 0;
	totalUnitCount = 0;
	struct archive* a;
	struct archive* ext;
	struct archive_entry* entry;
	int flags;
	int r;

	/* Select which attributes we want to restore. */
	flags = ARCHIVE_EXTRACT_TIME;
	flags |= ARCHIVE_EXTRACT_PERM;
	flags |= ARCHIVE_EXTRACT_ACL;
	flags |= ARCHIVE_EXTRACT_FFLAGS;

	// Calculate decompressed size
	a = archive_read_new();
	archive_read_support_format_all(a);
	archive_read_support_filter_all(a);
	if ((r = archive_read_open_filename(a, fileToExtract.fileSystemRepresentation, 10240))) {
		archive_read_free(a);
		AppLog(@"Failed to open archive: %@", fileToExtract);
		return 1;
	}
	while ((r = archive_read_next_header(a, &entry)) != ARCHIVE_EOF) {
		if (r < ARCHIVE_OK) {
			fprintf(stderr, "%s\n", archive_error_string(a));
			AppLog(@"Error reading archive header: %s", archive_error_string(a));
		}
		if (r < ARCHIVE_WARN) {
			archive_read_close(a);
			archive_read_free(a);
			AppLog(@"Archive warning: %s", archive_error_string(a));
			return 1;
		}
		totalUnitCount += archive_entry_size(entry);
		progress.totalUnitCount += archive_entry_size(entry);
	}
	archive_read_close(a);
	archive_read_free(a);

	// Re-open the archive and extract
	a = archive_read_new();
	archive_read_support_format_all(a);
	archive_read_support_filter_all(a);
	if ((r = archive_read_open_filename(a, fileToExtract.fileSystemRepresentation, 10240))) {
		archive_read_free(a);
		AppLog(@"Failed to reopen archive for extraction: %@", fileToExtract);
		return 1;
	}
	ext = archive_write_disk_new();
	archive_write_disk_set_options(ext, flags);
	archive_write_disk_set_standard_lookup(ext);

	while ((r = archive_read_next_header(a, &entry)) != ARCHIVE_EOF) {
		if (r == ARCHIVE_EOF)
			break;
		if (r < ARCHIVE_OK) {
			fprintf(stderr, "%s\n", archive_error_string(a));
			AppLog(@"Error reading header: %s", archive_error_string(a));
		}
		if (r < ARCHIVE_WARN)
			break;

		NSString* currentFile = [NSString stringWithUTF8String:archive_entry_pathname(entry)];
		NSString* fullOutputPath = [extractionPath stringByAppendingPathComponent:currentFile];
		// printf("extracting %@ to %@\n", currentFile, fullOutputPath);
		archive_entry_set_pathname(entry, fullOutputPath.fileSystemRepresentation);

		r = archive_write_header(ext, entry);
		if (r < ARCHIVE_OK) {
			fprintf(stderr, "%s\n", archive_error_string(ext));
			AppLog(@"Error writing header: %s", archive_error_string(ext));
		} else if (archive_entry_size(entry) > 0) {
			r = copy_data(a, ext, progress);
			if (r < ARCHIVE_OK) {
				fprintf(stderr, "%s\n", archive_error_string(ext));
				AppLog(@"Error copying data: %s", archive_error_string(ext));
			}
			if (r < ARCHIVE_WARN)
				break;
		}
		r = archive_write_finish_entry(ext);
		if (r < ARCHIVE_OK) {
			fprintf(stderr, "%s\n", archive_error_string(ext));
			AppLog(@"Error finishing entry: %s", archive_error_string(ext));
		}
		if (r < ARCHIVE_WARN)
			break;
	}
	archive_read_close(a);
	archive_read_free(a);
	archive_write_close(ext);
	archive_write_free(ext);

	return 0;
}
