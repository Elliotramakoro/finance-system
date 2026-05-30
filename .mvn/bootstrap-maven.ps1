Param([Parameter(ValueFromRemainingArguments=$true)]$args)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mavenDir = Join-Path $scriptDir "apache-maven"
$mvnCmd = Join-Path $mavenDir "bin\mvn.cmd"
if (-not (Test-Path $mvnCmd)) {
    Write-Host "Maven not found; downloading Apache Maven 3.9.7..."
    $mavenVersion = "3.9.7"
    $zipUrl = "https://archive.apache.org/dist/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
    $zipPath = Join-Path $scriptDir "apache-maven.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $scriptDir)
    Remove-Item $zipPath -Force
    Rename-Item -Path (Join-Path $scriptDir "apache-maven-$mavenVersion") -NewName "apache-maven"
}
& (Join-Path $mavenDir "bin\mvn.cmd") @args
exit $LASTEXITCODE
