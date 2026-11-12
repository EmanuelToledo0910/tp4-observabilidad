# Modifica targetPort a 9999
$patch = '[{"op":"replace","path":"/spec/ports/0/targetPort","value":9999}]'
$patch | Out-File -FilePath patch_port.json -Encoding ascii
kubectl -n gamecloud patch service gamecloud-ranking --type json --patch-file patch_port.json
Remove-Item patch_port.json -ErrorAction SilentlyContinue
