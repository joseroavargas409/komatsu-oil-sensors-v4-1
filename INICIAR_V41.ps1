$ErrorActionPreference='Stop'
$v41Root=$PSScriptRoot
$v41Url='http://127.0.0.1:8772'
try {
 $v41Config=Invoke-RestMethod -Uri ($v41Url+'/api/config') -TimeoutSec 2
 if($v41Config.fixed.version -eq '4.1'){Write-Host ('V4.1 disponible: '+$v41Url); exit 0}
 throw 'El puerto 8772 pertenece a otro programa.'
} catch {if($_.Exception.Message -like '*pertenece*'){throw}}
$v41NodeCommand=Get-Command node -ErrorAction SilentlyContinue
$v41Node=if($v41NodeCommand){$v41NodeCommand.Source}else{Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'}
if(-not(Test-Path -LiteralPath $v41Node)){throw 'Se requiere Node.js 22 o posterior.'}
Start-Process -FilePath $v41Node -ArgumentList @('server.mjs') -WorkingDirectory $v41Root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $v41Root 'server_stdout.log') -RedirectStandardError (Join-Path $v41Root 'server_stderr.log') | Out-Null
Write-Host ('V4.1 iniciada: '+$v41Url+'/?oil=95&sensors=6')
