### Pilet 1

**Loo skript `eksam1.sh`, mis teeb järgmised sammud:**

1. Küsib sisendina uue kasutaja nime ja parooli. Loob kasutaja ja grupi sama nimega.
2. Loob kausta `/home/eksam1/` ja sinna faili `eksam1.txt`, mille sisuks on `date` ja `who` väljund.
3. Kontrollib `if`-lausena, kas fail on õigustega `640`. Kui ei ole, parandab õigused ja väljastab hoiatuse.
4. Otsib `.bash_history` failist read, kus on `sudo`, ja salvestab need faili `/home/eksam1/sudo_kasud.txt`.
5. Loob funktsiooni `varunda`, mis teeb etteantud failist varukoopia kausta `/home/eksam1/backup/` kuupäeva ja kellaajaga failinimega. Testib funktsiooni `sudo_käsud.txt` peal.
6. Lisab crontab’i kirje, mis varundab iga päev kell 20:05 faili `eksam1.txt`.
7. Kontrollib, kas teenus `ssh` töötab. Kui ei tööta, väljastab `Hoiatus: ssh ei tööta!`.
8. Skripti lõpus kuvab: **“Pilet 1 lõpetatud edukalt.”**

---

### Pilet 2

**Loo skript `eksam2.sh`, mis teeb järgmised sammud:**

1. Küsib kasutajalt kaks nime sisendina. Loob mõlemad kasutajad parooliga, mis on sama, mis kasutajanimi.
2. Loob grupi `eksamigr2` ja lisab mõlemad kasutajad sinna.
3. Loob kataloogi `/home/eksam2/andmed` ja 5 faili (`fail1.txt … fail5.txt`), mille sisuks on `hostname` ja `uptime` väljund.
4. Muudab õigused nii, et: omanik saab lugeda ja kirjutada, grupp ainult lugeda, teised mitte midagi.
5. Kontrollib `if`-lausena, kas `fail3.txt` on õigustega `640`. Kui pole, parandab õigused ja kirjutab logisse `eksam2.log`.
6. Loob funktsiooni `varunda`, mis võtab argumendina kausta ja arhiveerib selle `tar.gz` formaati. Varundab `andmed` kataloogi kausta `/home/eksam2/backup/`.
7. Lisab crontab’i kirje, mis varundab `andmed` kataloogi iga päev kell 19:45.
8. Kontrollib, kas teenus `cron` töötab. Kui töötab, väljastab “cron aktiivne”, muul juhul hoiatuse.
9. Skripti lõpus kuvab: **“Pilet 2 lõpetatud edukalt.”**

---

### Pilet 3

**Loo skript `eksam3.sh`, mis teeb järgmised sammud:**

1. Küsib kasutajalt sisendina uue grupi nime. Loob grupi ja kasutaja `eksam3` ning lisab kasutaja loodud gruppi.
2. Loob kataloogi `/home/eksam3/projekt` ja sinna faili `projekt.txt`, mille sisuks on käsu `ls -l /etc` väljund.
3. Kontrollib `if`-lausena, kas fail eksisteerib ja on õigustega `600`. Kui õigused ei klapi, parandab need ja väljastab hoiatuse ekraanile.
4. Loob 3 alamkataloogi (`kaust1 … kaust3`) ja igasse faili `info.txt`, mille sisuks on `ps aux | head -5` väljund.
5. Otsib `.bash_history` failist read, kus on `apt`, ja salvestab need faili `/home/eksam3/projekt/apt_kasud.txt`.
6. Loob funktsiooni `varunda`, mis teeb varukoopia failist või kataloogist ja salvestab selle `backup` kausta kuupäeva ja kellaajaga. Testib funktsiooni `projekt.txt` peal.
7. Lisab crontab’i kirje, mis varundab `projekt` kataloogi igal pühapäeval kell 21:00.
8. Kontrollib teenuse `mysql` olekut ja väljastab vastava teate.
9. Skripti lõpus kuvab: **“Pilet 3 lõpetatud edukalt.”**

---

### Pilet 4

**Loo skript `eksam4.sh`, mis teeb järgmised sammud:**

1. Küsib sisendina kasutajanime ja parooli. Loob kasutaja ning lisab ta gruppi `eksamigr4`. Kui gruppi ei ole, loob selle.
2. Loob kataloogi `/home/eksam4/` ja sinna faili `kasutajad.txt`, mille sisuks on kõik kasutajad süsteemist (`cut -d: -f1 /etc/passwd`).
3. Kontrollib `if`-lausena, kas fail `kasutajad.txt` on olemas ja õigustega `640`. Kui mitte, parandab õigused ja lisab teate faili `eksam4.log`.
4. Loob kataloogi `logid` ja salvestab sinna käskude `df -h` ja `free -m` väljundid eraldi failidesse.
5. Otsib `.bash_history` failist kõik read, kus on `nano`, ja salvestab need faili `nano_kasud.txt`.
6. Loob funktsiooni `varunda`, mis pakib kokku kogu `/home/eksam4/` kataloogi ja salvestab selle `backup` kataloogi.
7. Lisab crontab’i kirje, mis käivitab varunduse iga päev kell 18:30.
8. Kontrollib teenuse `apache2` olekut ja väljastab teate.
9. Skripti lõpus kuvab: **“Pilet 4 lõpetatud edukalt.”**

---

### Pilet 5

**Loo skript `eksam5.sh`, mis teeb järgmised sammud:**

1. Küsib kasutajalt sisendina grupi nime. Loob grupi ja kasutaja `eksam5`, lisab kasutaja gruppi.
2. Loob kataloogi `/home/eksam5/projekt` ja 5 faili kujul `fail1.txt … fail5.txt`, mille sisuks on käsu `uptime` väljund.
3. Kontrollib `if`-lausena, kas `fail5.txt` on õigustega `600`. Kui mitte, parandab õigused ja väljastab teate ekraanile.
4. Loob alamkaustad `kaust1 … kaust3`, igasse faili `info.txt`, mille sisuks on käsu `id` väljund.
5. Otsib `.bash_history` failist kõik read, kus on `chmod`, ja salvestab need faili `eksam5.log`.
6. Loob funktsiooni `varunda`, mis arhiveerib failid ja lisab arhiveeritud failile kuupäeva ning kellaaja. Testib funktsiooni `fail5.txt` peal.
7. Lisab crontab’i kirje, mis varundab `projekt` kataloogi iga päev kell 22:00.
8. Kontrollib teenuse `cron` olekut ja väljastab teate.
9. Skripti lõpus kuvab: **“Pilet 5 lõpetatud edukalt.”**

---

### Pilet 6

**Loo skript `eksam6.sh`, mis teeb järgmised sammud:**

1. Küsib sisendina uue kasutaja nime. Loob kasutaja parooliga `eksam6` ja lisab ta gruppi `eksamigr6`.
2. Loob kataloogi `/home/eksam6/andmed` ja sinna faili `oluline.log`, mille sisuks on käsu `dmesg | tail -20` väljund.
3. Kontrollib `if`-lausena, kas fail on olemas. Kui ei ole, kuvab hoiatuse ja lõpetab skripti. Kui on, kontrollib õigused ja vajadusel parandab need (640).
4. Loob kataloogi `raportid` ja sinna faili `protsessid.txt`, mille sisuks on `ps aux | head -10`.
5. Otsib `.bash_history` failist kõik read, kus on `useradd`, ja salvestab need faili `useradd_kasud.txt`.
6. Loob funktsiooni `varunda`, mis varundab antud failitee ja salvestab tulemuse `backup` kausta. Testib seda `protsessid.txt` peal.
7. Lisab crontab’i kirje, mis käivitab varunduse igal ööl kell 01:15.
8. Kontrollib teenuse `ssh` olekut ja väljastab teate.
9. Skripti lõpus kuvab: **“Pilet 6 lõpetatud edukalt.”**

---

### Pilet 7

**Loo skript `eksam7.sh`, mis teeb järgmised sammud:**

1. Küsib kasutajalt sisendina kasutajanime ja grupi nime. Loob kasutaja ja grupi, parool sama, mis kasutajanimi, ning lisab kasutaja gruppi.
2. Loob kataloogi `/home/eksam7/test` ja sinna 10 faili (`test1.txt … test10.txt`), mille sisuks on `date` ja `uptime` väljund.
3. Kontrollib `if`-lausena, kas fail `test7.txt` on õigustega `600`. Kui mitte, parandab õigused ja kirjutab logi `eksam7.log`.
4. Loob kataloogi `teenused` ja faili `teenused.txt`, mille sisuks on teenuste `ssh`, `cron` ja `mysql` olek.
5. Otsib `.bash_history` failist kõik read, kus on `apt install`, ja salvestab need faili `paigaldused.txt`.
6. Loob funktsiooni `varunda`, mis arhiveerib kõik `teenused` kataloogi failid ja salvestab need `backup` kausta kuupäeva ja kellaajaga.
7. Lisab crontab’i kirje, mis varundab `test` kataloogi iga päev kell 20:30.
8. Skripti lõpus kuvab: **“Pilet 7 lõpetatud edukalt.”**

---

### Pilet 8

**Loo skript `eksam8.sh`, mis teeb järgmised sammud:**

1. Küsib sisendina kaks nime – esimene kasutajale, teine grupile. Loob mõlemad ja lisab kasutaja loodud gruppi.
2. Loob kataloogi `/home/eksam8/logid` ja sinna faili `jooksvahetk.txt`, mille sisuks on `uptime` ja `who`.
3. Kontrollib `if`-lausena, kas failil on õigused `640`. Kui mitte, parandab õigused ja väljastab ekraanile hoiatuse.
4. Loob alamkaustad `kaustA … kaustC` ja igasse faili `sisu.txt`, mille sisuks on `ls -l /home`.
5. Otsib `.bash_history` failist kõik read, kus on `passwd`, ja salvestab need faili `paroolid.txt`.
6. Loob funktsiooni `varunda`, mis varundab faili või kausta ja lisab failinimele kuupäeva ning kellaaja. Testib funktsiooni `jooksvahetk.txt` peal.
7. Lisab crontab’i kirje, mis varundab `logid` kataloogi igal esmaspäeval kell 10:00.
8. Kontrollib teenuse `systemd-journald` olekut. Kui ei tööta, väljastab hoiatuse.
9. Skripti lõpus kuvab: **“Pilet 8 lõpetatud edukalt.”**

---

### Pilet 9

**Loo skript `eksam9.sh`, mis teeb järgmised sammud:**

1. Küsib sisendina uue kasutaja nime. Loob kasutaja parooliga sama, mis nimi, ja lisab ta gruppi `eksamigr9`.
2. Loob kataloogi `/home/eksam9/projekt` ja sinna faili `süsteem.txt`, mille sisuks on `uname -a` ja `lsb_release -a`.
3. Kontrollib `if`-lausena, kas fail eksisteerib ja on õigustega `640`. Kui mitte, parandab õigused ja logib vea faili `eksam9.log`.
4. Loob 3 faili `teenus1.txt … teenus3.txt`, mille sisuks on teenuste `ssh`, `cron` ja `apache2` olek.
5. Otsib `.bash_history` failist read, kus on `rm`, ja salvestab need faili `kustutused.txt`.
6. Loob funktsiooni `varunda`, mis arhiveerib `projekt` kataloogi ja salvestab selle `backup` kausta kuupäeva-kellaajaga failina.
7. Lisab crontab’i kirje, mis varundab kogu `/home/eksam9` kataloogi igal ööl kell 02:00.
8. Skripti lõpus kuvab: **“Pilet 9 lõpetatud edukalt.”**

---

### Pilet 10

**Loo skript `eksam10.sh`, mis teeb järgmised sammud:**

1. Küsib sisendina kasutajanime ja grupi nime. Loob mõlemad ning lisab kasutaja gruppi.
2. Loob kataloogi `/home/eksam10/andmed` ja sinna faili `disk.txt`, mille sisuks on käsu `df -h` väljund.
3. Kontrollib `if`-lausena, kas fail on õigustega `600`. Kui mitte, parandab õigused ja kuvab ekraanile hoiatuse.
4. Loob 5 faili `proc1.txt … proc5.txt`, mille sisuks on `ps aux | head -n 5`.
5. Otsib `.bash_history` failist kõik read, kus on `mkdir`, ja salvestab need faili `kataloogid.txt`.
6. Loob funktsiooni `varunda`, mis varundab etteantud faili ja lisab failinimele kuupäeva ning kellaaja. Testib funktsiooni `disk.txt` peal.
7. Lisab crontab’i kirje, mis varundab `andmed` kataloogi iga päev kell 23:45.
8. Kontrollib teenuse `mysql` olekut ja väljastab teate.
9. Skripti lõpus kuvab: **“Pilet 10 lõpetatud edukalt.”**

---
Edu

