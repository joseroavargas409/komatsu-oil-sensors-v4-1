"""Select Rust's matched, open GNU self-contained linker for host builds on Windows."""
from pathlib import Path
import os,subprocess,sys
compiler=sys.argv[1];args=sys.argv[2:]
target=''
if '--target' in args:target=args[args.index('--target')+1]
if os.name=='nt' and not target.startswith('wasm'):
 toolchain=Path(compiler).resolve().parents[1]
 platform='x86_64-pc-windows-gnu'
 args += ['-C','linker='+str(toolchain/'lib/rustlib'/platform/'bin/rust-lld.exe'),'-C','linker-flavor=ld.lld','-C','link-self-contained=yes','-L','native='+str(toolchain/'lib/rustlib'/platform/'lib/self-contained')]
raise SystemExit(subprocess.call([compiler,*args]))
