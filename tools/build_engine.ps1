$ErrorActionPreference='Stop'
$v41Root=Split-Path $PSScriptRoot
$v41Old=Join-Path (Split-Path $v41Root) 'komatsu_oil_sensors_v4_2026-10-12'
$v41Toolchain=Join-Path $v41Old 'tools\rustup\toolchains\stable-x86_64-pc-windows-gnu'
if(-not(Test-Path -LiteralPath (Join-Path $v41Toolchain 'bin\rustc.exe'))){
 $v41Rustup=Get-Command rustup -ErrorAction SilentlyContinue
 if(-not $v41Rustup){throw 'Se requiere Rust GNU para reconstruir. La aplicación entregada ya incluye el motor compilado.'}
 $v41Compiler=& $v41Rustup.Source which rustc --toolchain stable-x86_64-pc-windows-gnu
 if($LASTEXITCODE -ne 0){throw 'Instala el toolchain stable-x86_64-pc-windows-gnu y el target wasm32-unknown-unknown.'}
 $v41Toolchain=Split-Path (Split-Path $v41Compiler)
}
$v41Python=Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if(-not(Test-Path -LiteralPath $v41Python)){
 $v41PythonCommand=Get-Command python -ErrorAction SilentlyContinue
 if(-not $v41PythonCommand -or $v41PythonCommand.Source -like '*WindowsApps*'){throw 'Para reconstruir en Windows se requiere Python 3 instalado. No se requiere para ejecutar la aplicación.'}
 $v41Python=$v41PythonCommand.Source
}
$env:CARGO_HOME=Join-Path $v41Root '.cargo_home'
$env:RUSTC=Join-Path $v41Toolchain 'bin\rustc.exe'
$env:PATH=(Join-Path $v41Toolchain 'bin')+';'+$env:PATH
$env:RUSTFLAGS=''
$v41Wrapper=Join-Path $PSScriptRoot 'rustc_wrapper.cmd'
('@echo off'+[Environment]::NewLine+'"'+$v41Python+'" "'+(Join-Path $PSScriptRoot 'rustc_wrapper.py')+'" %*') | Set-Content -LiteralPath $v41Wrapper
$env:RUSTC_WRAPPER=$v41Wrapper
Set-Location -LiteralPath $v41Root
& (Join-Path $v41Toolchain 'bin\cargo.exe') build --offline --locked --release --manifest-path engine/Cargo.toml --target wasm32-unknown-unknown --lib
if($LASTEXITCODE -ne 0){throw 'WebAssembly build failed'}
Copy-Item -LiteralPath engine/target/wasm32-unknown-unknown/release/oa2is_oil_engine.wasm -Destination dashboard/oil_engine.wasm
