# ArrowSphereAPI
Tässä Git Repossa on esimerkki miten voit hyödyntää laskutusdataa ArrowSphere järjestelmästä.
Laskutusdataa saa ArrowSpherestä erilaisilla tavoilla ja tässä esimerkissä rakennettu yksi malli.
Mallissa rakennetaan kaksi Azure funktiota jotka tekevät seuraavia asioita:

GetAzureBillingDetails.ps1
  - Käy läpi kaikki asiakkaat ja listaa asiakkaiden Azure lisenssit (Huom. Azure Plan vs Azure Legazy)
  - Jokaista lisenssiä vasten haetaan edellisen kuukauden kulutus ja tehdään pyyntö ArrowSphereen kulutuksen yksityikohdista (Excel-tiedosto)
  - Kulutuspyynnöstä saadaan referenssi koodi joka tallennetaan asiakas- ja lisenssitiedon kanssa Azure aTable Storageeen
  - Azure funktio ajetaan esim joka kuukauden 10. päivä tai kunnes laskutusdata on saatavilla (TimeTrigger)

ProcessBillingStatement.ps1
  - Azure funktio kuuntelee HTTP-triggeriä
  - Kun ArrowSphere palauttaa laskutusdatan yksityiskohdat niin tämä funktio käsittelee ne.
  - Referenssikoodin avulla laskutus yhdistetään asiakkaaseen ja tieto lähetetään Teams kanavalle.

![image](https://user-images.githubusercontent.com/69797126/126116597-cd893c60-fad8-4f1b-b46a-d9a661b8546a.png)

# Valmistelut
1. Tarvitset ArrowSphere tunnuksen jolla on oikeus luoda API avaimia https://xsp.arrow.com/
2. API avaimen luontiin löytyy ohjeet täältä: https://xsp.arrow.com/apidoc (https://xsp.arrow.com/apidoc#section/Set-up/API-Authentication:-Generate-API-Keys)
3. Tarvitset Azure tilauksen johon luodaan Azure funktiot sekä Table Storage
4. Jatkokehityksessä suosittelen https://www.postman.com/ työkalua API rajapinnan testaamiseen

# Azure Funktioiden luominen
1. Luodaan Azure funktio palvelu

**Funktiot rakennetaan powershell pohjalle. Huomio että funktion nimi pitää olla uniikki!**
![image](https://user-images.githubusercontent.com/69797126/126118522-422cd17b-de4f-4362-adab-7c5d8d88f3a4.png)

**Funktio voi olla serverless pohjainen**
![image](https://user-images.githubusercontent.com/69797126/126118651-6bd93753-d9c7-4f5c-8f1f-761abd27c3b4.png)

**Suositeltavaa enabloida application insights debuggausta varten**
![image](https://user-images.githubusercontent.com/69797126/126118721-d5473ea6-3c50-49f3-b519-995aaba50430.png)

2. Luodaan itse funktiot

![image](https://user-images.githubusercontent.com/69797126/126119330-f22d2b6a-79ee-438f-b414-34a25b50597f.png)

**Luodaan GetAzureBillingDetails joka ajastetaan suorittamaan joka kuukauden 10 päivä**
![image](https://user-images.githubusercontent.com/69797126/126119880-3a08bd82-76ff-4e46-8f22-1543f3167dcd.png)

**Luodaan ProcessBillingStatement joka suoritetaan HTTP triggerin avulla**

![image](https://user-images.githubusercontent.com/69797126/126120311-1fe4cdfb-b81c-4261-9632-80fbc78bde8d.png)

**Tuloksena 2 Azure funktiota. Toinen Timer- ja toinen HTTP-triggeillä**
![image](https://user-images.githubusercontent.com/69797126/126120483-962b9131-ca5e-4cf7-a3d6-bb39ea5d831a.png)

# Azure Table Storage luominen
1. Luodaan uusi taulu samaan storage accountiin minkä Azure funktio loi meille

![image](https://user-images.githubusercontent.com/69797126/126121443-89211616-11e0-4fcc-9c14-a09770343934.png)

**Luodaan uusi taulu nimeltään MyreferenceData**

![image](https://user-images.githubusercontent.com/69797126/126121296-af90d51a-49d9-412d-89da-6015908f60f9.png)

**Taulukon dataa voi tutkia suoraan portaalista tai Azure Storage Explorer ohjelmalla (https://azure.microsoft.com/en-us/features/storage-explorer/)**
![image](https://user-images.githubusercontent.com/69797126/126121889-a483f054-52f2-466a-8845-c6f41fce72a1.png)

