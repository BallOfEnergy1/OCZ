# OCZ2 (OCZip2)
A program for a Minecraft mod called OpenComputers that centers around allowing easy compression and decompression of files and data.

## Compatibility
  OCZ has compatibility for other helper shell scripts and can be used in external programs. The functions exposed by the library consists of the following:

    ocz.compress(data, customValue, checksum, type) - Returns the data in a compressed format readable by the OCZ decompression function.
    customValue, checksum, and type are all optional fields.

    ocz.decompress(data) - Takes in compressed data and returns the decompressed data in a string.

    ocz.compressFile(filePath, customValue, checksum, type) - Takes in a global filepath, reads data from the file, then compresses the data.
    customValue, checksum, and type are all optional fields.    

    ocz.decompressFile(filePath) - Takes in a global filepath, reads data from the file, then decompresses the data.

    ocz.runCompressed(filePath) - Takes in a global filepath and directly runs the compressed file.
