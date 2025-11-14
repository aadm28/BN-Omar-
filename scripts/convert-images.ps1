<#
PowerShell script to convert images in the project to WebP and AVIF.
Usage: Open PowerShell in the project root and run:
  ./scripts/convert-images.ps1

Requirements (recommended):
- ImageMagick (magick) with AVIF support OR
- cwebp (from libwebp) and avifenc (from libavif)

What it does:
- Finds JPG/JPEG/PNG files under `assets` and `assets/images`.
- Skips files already having .webp/.avif counterparts unless `-Force` specified.
- Produces `.webp` and `.avif` versions next to original files.

Options:
- -QualityWebP (default 80)
- -QualityAVIF (default 60)
- -Force to overwrite existing outputs
#>
param(
    [int]$QualityWebP = 80,
    [int]$QualityAVIF = 60,
    [switch]$Force
)

Function Test-CommandExists($name){
    return (Get-Command $name -ErrorAction SilentlyContinue) -ne $null
}

$useMagick = Test-CommandExists magick
$useCwebp = Test-CommandExists cwebp
$useAvifenc = Test-CommandExists avifenc

if(-not ($useMagick -or ($useCwebp -and $useAvifenc))) {
    Write-Warning "No suitable image conversion tools found. Install ImageMagick (magick) or cwebp+avifenc. The script will still list files to convert."
}

$root = Join-Path (Get-Location) "assets"
$patterns = "*.jpg","*.jpeg","*.png","*.JPG","*.PNG","*.JPEG"
$files = Get-ChildItem -Path $root -Recurse -Include $patterns -File

if(-not $files){
    Write-Host "No image files found under $root"
    exit 0
}

Write-Host "Found $($files.Count) image(s). Converting to WebP and AVIF..."

foreach($f in $files){
    $in = $f.FullName
    $webp = [System.IO.Path]::ChangeExtension($in, ".webp")
    $avif = [System.IO.Path]::ChangeExtension($in, ".avif")

    if(-not $Force){
        if(Test-Path $webp){ Write-Host "Skipping WebP (exists): $webp"; } 
    }
    if(-not $Force){
        if(Test-Path $avif){ Write-Host "Skipping AVIF (exists): $avif"; }
    }

    if($useMagick){
        try{
            if($Force -or -not (Test-Path $webp)){
                Write-Host "magick -> WebP: $($f.Name)"
                magick "${in}" -quality $QualityWebP "${webp}"
            }
            if($Force -or -not (Test-Path $avif)){
                Write-Host "magick -> AVIF: $($f.Name)"
                magick "${in}" -quality $QualityAVIF "${avif}"
            }
        } catch{
            Write-Warning "magick conversion failed for $($f.Name): $_"
        }
    } else {
        if($useCwebp){
            if($Force -or -not (Test-Path $webp)){
                Write-Host "cwebp -> WebP: $($f.Name)"
                & cwebp -q $QualityWebP "${in}" -o "${webp}"
            }
        }
        if($useAvifenc){
            if($Force -or -not (Test-Path $avif)){
                Write-Host "avifenc -> AVIF: $($f.Name)"
                & avifenc --min $QualityAVIF --max $QualityAVIF "${in}" "${avif}"
            }
        }
    }
}

Write-Host "Conversion finished. Review generated .webp and .avif files under assets/."
Write-Host "Next: update HTML to reference AVIF/WebP via <picture> tags (already added where appropriate)."
