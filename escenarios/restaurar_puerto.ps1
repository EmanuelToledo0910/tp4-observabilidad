# Restaura targetPort a http
$patch = '[{"op":"replace","path":"/spec/ports/0/targetPort","value":"http"}]'
$patch | Out-File -FilePath patch_port.json -Encoding ascii
kubectl -n gamecloud patch service gamecloud-ranking --type json --patch-file patch_port.json
Remove-Item patch_port.json -ErrorAction SilentlyContinue
