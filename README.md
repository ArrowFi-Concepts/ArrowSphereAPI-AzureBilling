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

# Azure valmistelut
1. Luodaan Azure funktio palvelu

**Funktiot rakennetaan powershell pohjalle. Huomio että funktion nimi pitää olla uniikki!**
![image](https://user-images.githubusercontent.com/69797126/126117856-08b1ffbe-f6dc-4d85-af09-50d152341be3.png)

**Funktio voi oll serverless pohjainen**
![image](https://user-images.githubusercontent.com/69797126/126117870-012772cc-967c-4106-9587-158cc24372a5.png)

**Suositeltavaa enabloida application insights debuggausta varten**
![image](https://user-images.githubusercontent.com/69797126/126117877-9ed00950-c196-4226-bc64-7e15c32193e6.png)



