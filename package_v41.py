"""Package explicit open-source application files; never include investigation credentials."""
from pathlib import Path
import hashlib,json,zipfile
root=Path(__file__).resolve().parent;release=root/'release';release.mkdir(exist_ok=True)
paths=set()
def add_tree(name):
 for p in (root/name).rglob('*'):
  if p.is_file() and not any(q in ('.git','target','__pycache__') for q in p.relative_to(root).parts):paths.add(p)
for name in ('dashboard','engine/src','engine/vendor','build/salva','licenses','.cargo','research'):add_tree(name)
for name in ('LICENSE','README.md','THIRD_PARTY_NOTICES.md','open_source_audit.json','package.json','server.mjs','run_case.mjs','build_cases.mjs','verify.mjs','verify_sensors.mjs','INICIAR_V41.ps1','package_v41.py','engine/Cargo.toml','engine/Cargo.lock','engine/target/release/oa2is_oil_native.exe','tools/build_native.ps1','tools/build_engine.ps1','tools/rustc_wrapper.py'):paths.add(root/name)
for liters in (55,95,125):
 for name in ('result.json','summary.json','positions.bin'):paths.add(root/f'data/volumes/{liters}'/name)
add_tree('data/case_exports')
for name in ('coupling_moving','coupling_stopped','resolution_16mm','resolution_8mm'):add_tree('data/'+name)
for name in ('verification_v41.json','sensor_tests.json','rust_tests.log','refinement_v41.json','cfd_shear_validation.json','preservation_v41.json','v4_copy_verified.json','tools_status.json','metadata_correction.json','parallel_dependencies.json'):
 paths.add(root/'reports'/name)
for name in ('reference.json','reference.csv','export_reference.py','create_shear_bench.py'):paths.add(root/'cfd'/name)
add_tree('cfd/shear_bench');add_tree('cfd/completed_shear')
# The old 118.75 L interrupted reference is not part of the accepted 95 L dataset.
paths.discard(root/'cfd/completed_shear/postProcessing/oilVolume/0/volFieldValue.dat')
for p in (root/'reports').glob('v41_*.png'):paths.add(p)
manifest=[]
for p in sorted(paths):
 if not p.is_file():raise ValueError('Required file missing: '+str(p))
 name=p.relative_to(root).as_posix();assert not any(t in name.lower() for t in ('id_ed25519','known_hosts','.qcow2','downloads/','tools/7zip'))
 manifest.append({'path':name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
archive=release/'komatsu_oil_sensors_v4_1_portable_2026-10-13.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in sorted(paths):z.write(p,p.relative_to(root).as_posix())
 z.writestr('MANIFEST_V41.json',json.dumps(manifest,indent=2))
with zipfile.ZipFile(archive) as z:
 for m in manifest:assert hashlib.sha256(z.read(m['path'])).hexdigest()==m['sha256']
digest=hashlib.sha256(archive.read_bytes()).hexdigest();report={'archive':archive.name,'sha256':digest,'files':len(manifest),'bytes':archive.stat().st_size,'all_archive_hashes_verified':True,'private_keys_and_vm_images_excluded':True}
(release/'SHA256.txt').write_text(digest+'  '+archive.name+'\n',encoding='utf-8');(release/'package_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
