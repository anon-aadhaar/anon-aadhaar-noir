# Measure execution time in milliseconds using `time` and `awk`
{ time (bb verify -k ./target/vk -p ./target/proof) } 2>&1 | awk '/real/ { match($0, /([0-9]+)m([0-9]+)s/, a); if (a[1] == "") a[1] = 0; if (a[2] == "") a[2] = 0; printf "%.0f milliseconds\n", (a[1] * 60000 + a[2] * 1000) }'
