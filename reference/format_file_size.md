# Format a file size in bytes as a human-readable string

Format a file size in bytes as a human-readable string

## Usage

``` r
format_file_size(size)
```

## Arguments

- size:

  Numeric. File size in bytes.

## Value

A character string such as `"1.4 MB"` or `"340 KB"`.

## Examples

``` r
format_file_size(1048576)   # "1 MB"
#> [1] "1 MB"
format_file_size(512)       # "512 B"
#> [1] "512 B"
```
