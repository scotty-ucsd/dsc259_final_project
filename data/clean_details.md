## header info

* `head -3 data/outage.csv | cut -d ',' -f 1 > outage_header_info.csv`


## QAD clean csv

* `head -6 data/outage.csv | tail -1 | cut -d ',' -f 2- > data/outage_clean.csv`

* `tail -n +8 data/outage.csv | cut -d ',' -f 2- >> data/outage_clean.csv`
