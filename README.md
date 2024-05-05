# OCZ (OCZip)
A program for a Minecraft mod called OpenComputers that centers around allowing easy compression and decompression of files and data.
Very WIP.

## Compatibility
  OCZ has compatibility for other helper shell scripts and can be used in external programs. The functions exposed by the library consists of the following:
    
    ocz.changeSetting(setting, newValue) - Safely changes a setting in the _G.ocz_settings table.
    
    ocz.compress(data)) - Returns the data in a compressed format readable by the OCZ decompression function.
    
    ocz.decompress(data, [toss]) - Takes in compressed data and returns the decompressed data in a string.
    If toss is true then the function will immediately return "" and false if the checksum fails.
    The second return field is true if the file checksum suceeds, false if it does not match.

    ocz.compressFile(filePath, [newFilePath]) - Takes in a global filepath, reads data from the file, compresses the data, and then writes the data to the file at newFilePath.
    If newFilePath is nil, then the compressed contents of the file are returned. If the file does not exist then it will be created; if the file does exist then it will be overridden.

    ocz.decompressFile(filePath, [newFilePath]) - Takes in a global filepath, reads data from the file, decompresses the data, and then writes the data to the file at newFilePath.
    If newFilePath is nil, then the decompressed contents of the file are returned. If the file does not exist then it will be created; if the file does exist then it will be overridden.

    ocz.recursiveCompress(directoryPath, newDirectoryPath) - Takes in a global directory path, recursively compressed all files in the directory, then writes to an identical structure in newDirectoryPath. 
    (Ex: The file "/home/files/test1.txt" will be compressed to the directory "/home/compressed/files/test1.txt" when newDirectoryPath is "/home/compressed".)

    ocz.recursiveDecompress(directoryPath, newDirectoryPath) - Takes in a global directory path, recursively compressed all files in the directory, then writes to an identical structure in newDirectoryPath.

    ocz.runCompressedFile(filePath) - Takes in a global filepath and directly runs the compressed file. This function is NOT safe, as it can allow users to directly execute code via OCZ.
    This function can be completely disabled using the _G.ocz_settings.disable_compressed_run option.
  
## Settings

  To change compression settings, you must set these in your program in the correct format.
  If invalid values are given to the `changeSetting()` function, then the value will not be changed and an error will be logged in the logging directory.
  It is suggested to use the `changeSetting()` function instead of setting the variables directly to ensure that incorrect values are not inserted.
  

  -----------------------------------------------------------------------------------

  Do not modify these or anything inside of them to avoid breaking the library.
  
  _G.ocz_settings.prog:
    Contains important global variables for the library to use.
    
  _G.ocz_settings.override:
    Contains override settings for use during decompression.
    
  -----------------------------------------------------------------------------------
  
  _G.ocz_settings.compression: (default true)
    Determines if the library should compress the data at all.
  
  _G.ocz_settings.algorithm_version: (default 2)
    Sets the version of the algorithm to be used;
    If algorithm 1 is selected while `use_data_card` is false then algorithm 2 will be used by default.
    0 is no compression;
    1 is inflate/deflate compression using the data card;
    2 is LZW compression using the lualzw library.
  
  _G.ocz_settings.use_data_card: (default true)
    This setting is to be set to false when a data card is not inserted to keep the program from faulting.
    Errors are caught, but the returns they may give can cause some severe issues. All errors are logged in the logging directory.
    *SHA256 checksums will not be supported when this is false.*
    The MD5 and CRC32 implementation in pure lua will be used instead of the data card version even when enabled. This is due to data length limitations.
    Data card MD5 and CRC32 implementations can be forced using the `force_data_card` setting.
    
  _G.ocz_settings.checksum: (default true)
    This option can be used to enable or disable the checksum for the file.
    Mainly for smaller files that may not need a checksum/increases the size beyond desirable levels.
    
  _G.ocz_settings.checksum_type: (default MD5)
    This setting sets the checksum type to be used (active when _G.ocz_settings.checksum is true), possible options are:
      "MD5"    (256 bit) - Standard hash algorithm, used by default and when data card is disabled.
      "SHA256" (256 bit) - Very overkill, takes up a large amount of space, but provides the most amount of protection if storing important data is needed.
      "CRC32"  (32 bit)  - Standard error-detecting hash algorithm, very useful for small files that don't need to be ultra-secure but still need some checksum.
      Note: If SHA256 is selected when the data card option is disabled, the MD5 algorithm will be used instead.
      SHA256 does not support strings over 4KB/4000 characters.

  _G.ocz_settings.force_data_card: (default false)
    This setting can be enabled to force the program to use the data card. This can introduce major issues when attempting to compress large files/strings (>4KB).
    `use_data_card` must be true to use this setting, if a data card is not found then the program WILL fail and throw an uncaught error.
    Compressing a file/string while this setting is true and then attempting to decompress on a computer without a data card will cause an error.
