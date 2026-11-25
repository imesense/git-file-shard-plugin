# Reads the PE machine type of a Windows executable and prints the
# architecture it was built for (x64, arm64 or x86).
#
# Used by the Windows installer wrappers to keep the installer architecture
# in sync with the PyInstaller payload, because PyInstaller does not
# cross-compile.
#
# Usage:
#     detect-payload-arch.ps1 <path-to-exe>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Path
)

$ErrorActionPreference = 'Stop'

# PE/COFF layout constants, see the PE format specification: the MS-DOS
# header holds the offset of the PE header in `e_lfanew`, and the COFF file
# header that follows the `PE\0\0` signature starts with the machine type.
Set-Variable -Name DosHeaderSize -Value 0x40 -Option Constant
Set-Variable -Name PeHeaderPointerOffset -Value 0x3C -Option Constant
Set-Variable -Name PeSignature -Value 0x00004550 -Option Constant
Set-Variable -Name PeSignatureSize -Value 4 -Option Constant
Set-Variable -Name MachineFieldSize -Value 2 -Option Constant

# `IMAGE_FILE_MACHINE_*` values of the architectures the plugin ships.
Set-Variable -Name MachineArchitectures -Option Constant -Value @{
    0x014C = 'x86'      # IMAGE_FILE_MACHINE_I386
    0x8664 = 'x64'      # IMAGE_FILE_MACHINE_AMD64
    0xAA64 = 'arm64'    # IMAGE_FILE_MACHINE_ARM64
}

$resolved = (Resolve-Path -LiteralPath $Path).Path
$stream = [IO.File]::OpenRead($resolved)
try
{
    $reader = New-Object IO.BinaryReader($stream)

    if ($stream.Length -lt $DosHeaderSize)
    {
        throw "Not a PE file: $resolved"
    }

    $stream.Position = $PeHeaderPointerOffset
    $peOffset = $reader.ReadInt32()
    if ($peOffset -le 0 -or
        $peOffset -gt ($stream.Length - $PeSignatureSize - $MachineFieldSize))
    {
        throw "Not a PE file: $resolved"
    }

    $stream.Position = $peOffset
    if ($reader.ReadUInt32() -ne $PeSignature)
    {
        throw "Not a PE file: $resolved"
    }

    $machine = [int] $reader.ReadUInt16()
}
finally
{
    $stream.Dispose()
}

if (-not $MachineArchitectures.ContainsKey($machine))
{
    throw ('Unsupported PE machine type 0x{0:X4} in {1}' -f $machine, $resolved)
}

$MachineArchitectures[$machine]
