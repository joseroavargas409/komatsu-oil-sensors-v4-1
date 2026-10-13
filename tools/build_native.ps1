$ErrorActionPreference='Stop'
$v41Root=Split-Path $PSScriptRoot
$v41Tc=Join-Path (Split-Path $v41Root) 'komatsu_oil_sensors_v4_2026-10-12\tools\rustup\toolchains\stable-x86_64-pc-windows-gnu'
if(-not(Test-Path -LiteralPath (Join-Path $v41Tc 'bin\rustc.exe'))){
 $v41Rustup=Get-Command rustup -ErrorAction SilentlyContinue
 if(-not $v41Rustup){throw 'Para compilar se requiere el toolchain Rust GNU. Los resultados entregados funcionan sin compilar.'}
 $v41Compiler=& $v41Rustup.Source which rustc --toolchain stable-x86_64-pc-windows-gnu
 if($LASTEXITCODE -ne 0){throw 'Instala el toolchain stable-x86_64-pc-windows-gnu con rustup.'}
 $v41Tc=Split-Path (Split-Path $v41Compiler)
}
$env:RUSTC=Join-Path $v41Tc 'bin\rustc.exe'
$env:CARGO_HOME=Join-Path $v41Root '.cargo_home'
$env:PATH=(Join-Path $v41Tc 'bin')+';'+$env:PATH
$env:RUSTFLAGS='-C linker-flavor=ld.lld -C link-self-contained=yes -L native='+(Join-Path $v41Tc 'lib\rustlib\x86_64-pc-windows-gnu\lib\self-contained')
$env:CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=Join-Path $v41Tc 'lib\rustlib\x86_64-pc-windows-gnu\bin\rust-lld.exe'
Set-Location -LiteralPath $v41Root
& (Join-Path $v41Tc 'bin\cargo.exe') build --offline --locked --release --features native-parallel --manifest-path engine/Cargo.toml
if($LASTEXITCODE -ne 0){throw 'Native build failed'}
