/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Purpose:
 *   Hash utility for z/OS batch builds. Computes CRC32 over a source
 *   member and compares or updates a hash member in a PDSE.
 *
 * Platform requirements:
 *   - Runs under z/OS LE (31-bit is fine).
 *   - Uses DDNAME-based dataset access (no USS paths).
 *   - Hashes raw dataset bytes (EBCDIC as stored).
 *
 * Objects in this file:
 * +-------------------+----------------------------------------------+
 * | Object            | Description                                  |
 * +-------------------+----------------------------------------------+
 * | crc32_init_table  | Initialize CRC32 table                       |
 * | crc32_update      | Update CRC32 with bytes                      |
 * | hash_stream       | Compute CRC32 for an input stream            |
 * | read_hash_line    | Read CRC32 line from HASHIN DD               |
 * | write_hash_line   | Write CRC32 line to HASHOUT DD               |
 * | main              | Compare/update entrypoint                    |
 * +-------------------+----------------------------------------------+
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

#define LUZ40010 "LUZ40010 invalid arguments"
#define LUZ40011 "LUZ40011 unable to open source member"
#define LUZ40012 "LUZ40012 hash member missing or unreadable"
#define LUZ40013 "LUZ40013 hash mismatch"
#define LUZ40014 "LUZ40014 unable to update hash member"
#define LUZ40015 "LUZ40015 hash record format invalid"
#define LUZ40016 "LUZ40016 object member missing"

static uint32_t crc32_table[256];
static int crc32_table_ready = 0;

static void crc32_init_table(void) {
  uint32_t i;
  for (i = 0; i < 256; i++) {
    uint32_t c = i;
    int j;
    for (j = 0; j < 8; j++) {
      if (c & 1) {
        c = 0xEDB88320u ^ (c >> 1);
      } else {
        c = c >> 1;
      }
    }
    crc32_table[i] = c;
  }
  crc32_table_ready = 1;
}

static uint32_t crc32_update(uint32_t crc, const uint8_t *buf, size_t len) {
  size_t i;
  if (!crc32_table_ready) {
    crc32_init_table();
  }
  for (i = 0; i < len; i++) {
    crc = crc32_table[(crc ^ buf[i]) & 0xFFu] ^ (crc >> 8);
  }
  return crc;
}

static int hash_stream(FILE *fp, uint32_t *out_crc) {
  uint8_t buf[4096];
  size_t n;
  uint32_t crc = 0xFFFFFFFFu;

  while ((n = fread(buf, 1, sizeof(buf), fp)) > 0) {
    crc = crc32_update(crc, buf, n);
  }
  if (ferror(fp)) {
    return -1;
  }
  *out_crc = crc ^ 0xFFFFFFFFu;
  return 0;
}

static int read_hash_line(FILE *fp, uint32_t *out_crc) {
  char line[64];
  char *p;
  unsigned long val;

  if (fgets(line, sizeof(line), fp) == NULL) {
    return -1;
  }
  p = line;
  while (*p == ' ' || *p == '\t') {
    p++;
  }
  if (strncmp(p, "CRC32", 5) == 0) {
    p += 5;
  }
  while (*p == ' ' || *p == '\t') {
    p++;
  }
  if (sscanf(p, "%lx", &val) != 1) {
    return -1;
  }
  *out_crc = (uint32_t)val;
  return 0;
}

static int write_hash_line(FILE *fp, uint32_t crc) {
  char line[32];
  int n = snprintf(line, sizeof(line), "CRC32 %08X\n", (unsigned)crc);
  if (n <= 0 || n >= (int)sizeof(line)) {
    return -1;
  }
  return (fwrite(line, 1, (size_t)n, fp) == (size_t)n) ? 0 : -1;
}

static void usage(void) {
  fprintf(stderr, "%s\n", LUZ40010);
  fprintf(stderr, "Usage: HASHCMP <C|U> <MEMBER> <SRCPDS> <HASHPDS>\n");
}

int main(int argc, char **argv) {
  const char *mode;
  const char *member;
  const char *srcpds;
  const char *hashpds;
  FILE *src = NULL;
  FILE *hashfp = NULL;
  uint32_t actual = 0;
  uint32_t expected = 0;
  int rc = 0;

  if (argc < 5) {
    usage();
    return 8;
  }
  mode = argv[1];
  member = argv[2];
  srcpds = argv[3];
  hashpds = argv[4];
  if (mode == NULL || member == NULL || srcpds == NULL || hashpds == NULL) {
    usage();
    return 8;
  }

  src = fopen("DD:SRCIN", "rb");
  if (src == NULL) {
    fprintf(stderr, "%s: %s (%s)\n", LUZ40011, member, strerror(errno));
    return 12;
  }
  if (hash_stream(src, &actual) != 0) {
    fprintf(stderr, "%s: %s\n", LUZ40011, member);
    fclose(src);
    return 12;
  }
  fclose(src);

  if (mode[0] == 'C' || mode[0] == 'c') {
    FILE *objfp = fopen("DD:OBJIN", "rb");
    if (objfp == NULL) {
      fprintf(stderr, "%s: %s\n", LUZ40016, member);
      return 4;
    }
    fclose(objfp);
    hashfp = fopen("DD:HASHIN", "rb");
    if (hashfp == NULL) {
      fprintf(stderr, "%s: %s\n", LUZ40012, member);
      return 4;
    }
    if (read_hash_line(hashfp, &expected) != 0) {
      fprintf(stderr, "%s: %s\n", LUZ40015, member);
      fclose(hashfp);
      return 4;
    }
    fclose(hashfp);
    if (actual != expected) {
      fprintf(stderr, "%s: %s\n", LUZ40013, member);
      return 4;
    }
    return 0;
  }

  if (mode[0] == 'U' || mode[0] == 'u') {
    hashfp = fopen("DD:HASHOUT", "wb");
    if (hashfp == NULL) {
      fprintf(stderr, "%s: %s\n", LUZ40014, member);
      return 12;
    }
    if (write_hash_line(hashfp, actual) != 0) {
      fprintf(stderr, "%s: %s\n", LUZ40014, member);
      rc = 12;
    }
    fclose(hashfp);
    return rc;
  }

  usage();
  return 8;
}
