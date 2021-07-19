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

**Luodaan MyGetAzureBillingDetails joka ajastetaan suorittamaan joka kuukauden 10 päivä**
![image](https://user-images.githubusercontent.com/69797126/126119880-3a08bd82-76ff-4e46-8f22-1543f3167dcd.png)

**Luodaan MyProcessBillingStatement joka suoritetaan HTTP triggerin avulla**

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

# Azure funktioiden konfiguroiminen

**Azure funktion konfiguraatiossa on määritys AzureWebJobsStorage jossa on access key samaan storage accountiin minkä funktio loi**
![image](https://user-images.githubusercontent.com/69797126/126126163-8747dd2d-f1b4-4e1b-bf18-b4eda4ca1c3c.png)

**Täällä on myös meidän luoma MyreferenceData taulu johon funktioilla on pääsy kunhan se konfiguroidaan funktioiden sisään- ja/tai ulostulomuuttujiksi**

**Lisätään MyGetAzureBillingDetails ulostulomuuttujaksi MyreferenceData taulu (Add Output)**
![image](https://user-images.githubusercontent.com/69797126/126126590-08e3bda6-6589-453d-8adb-5313db2a9eb0.png)
**Huomio oletus muuttujan nimen muutos outputTable -> outputToTable (koska koodissa käytetään tätä nimeä**
![image](https://user-images.githubusercontent.com/69797126/126127400-3592ab0d-bd20-4147-88bc-bd5d1067e5f3.png)
**Käytetään muuttujaa jossa access key storage accountiin**
![image](https://user-images.githubusercontent.com/69797126/126127450-1726b5e0-18fb-4853-b659-890d047d725d.png)

**Lisätään MyProcessBillingStatement sisääntulo-muuttujaksi MyreferenceData taulu (Add Input)**
![image](https://user-images.githubusercontent.com/69797126/126129287-629e7bc7-9742-42a0-91bc-6b2c7cd65fa0.png)
![image](https://user-images.githubusercontent.com/69797126/126128865-ba4280e0-1f25-43fb-83d7-9139e9411d62.png)
![image](https://user-images.githubusercontent.com/69797126/126128991-b11e98bd-c21f-47fb-8468-df5e77b114ae.png)

# HTTP Trigger osoitteen taltiointi
**Etsi funktio MyProcessBillingStatement ja kopioi talteen HTTP triggerin osoite**
![image](https://user-images.githubusercontent.com/69797126/126140101-ebd01b70-d7de-420b-83ab-57bd4f3c5f50.png)


# Teams kanavan konfigurointi (web hook)
1. Luo valitsemaasi Teams ryhmään kanava jonne haluat viestit lähettää
2. Valitse kanava ja kanavan valikosta Connectors
![image](https://user-images.githubusercontent.com/69797126/126136267-83d34aa4-ac98-43a1-a763-762cef210d3d.png)
3. Etsi valikosta Incoming WebHook connector ja paina Add ja toisen kerran Add
![image](https://user-images.githubusercontent.com/69797126/126136563-36a2044f-6a83-4346-9040-7e959f0a35b8.png)
4. Lisäämisen jälkeen valitse Incoming WebHook connector ja valitse configure
**Anna connectorille nimi ja kuvake ja paina create**
![image](https://user-images.githubusercontent.com/69797126/126137262-e9ea57cb-bb5b-4587-946a-1ebcdd86378f.png)
5. Kopioi talteen connector URL ja paina done
![image](https://user-images.githubusercontent.com/69797126/126137596-ae38c5a2-80ee-4863-803a-8ab0cc146ba4.png)

# Azure Table Storage Shared Access Signature avaimen luonti
1. Mene luotuun storage accountiin ja luo table storagea varten Shared Access Signature jolla voidaan poistaa vanhoja merkintöjä. (Azure funktio ei tue tätä vielä)
![image](https://user-images.githubusercontent.com/69797126/126139085-09102df8-2d77-44a6-9660-3c7cac62e2cb.png)
2. Paina Generate SAS and connection string ja ota talteen kaikki, erityisesti SAS Token
![image](https://user-images.githubusercontent.com/69797126/126139278-7560772c-9e67-4b35-923c-6ec607be3d1f.png)


# Azure funktio skriptin sisältö
1. Kopioi MyGetAzureBillingDetails.ps1 sisältö siihen varattuun Azure funktioon

**Muuta seuraavat muuttujat ja tallenna**
#My table name
$tblName='CHANGE-TO-YOUR-TABLE-NAME'
#My Shared Access Signature #e.g. ?sv=2020-08-04&ss=...... 
$tblSAS='CHANGE-TO-YOUR-SAS'
#Table Storage Account FQDN e.g. https://arrowsphereapi.table.core.windows.net/ 
$storAcc = 'CHANGE-TO-YOUR-StorageAccountName'

#My HTTP Trigger URL
$TriggerURL = 'CHANGE-TO-YOUR-Trigger-URL'

$headers = @{
'Content-Type' = 'application/json'
'apikey' = 'CHANGE-TO-YOUR-APIKEY'
'Accept' = 'application/json'
}

![image](https://user-images.githubusercontent.com/69797126/126142839-3f8439a3-c077-48a4-9e2c-e0291313d5e7.png)
![image](https://user-images.githubusercontent.com/69797126/126143623-e7ca88d9-ec94-4a0f-9c12-3992c6bbf3aa.png)

2. Kopioi MyProcessBillingStatement.ps1 sisältö siihen varattuun Azure funktioon
**Muuta seuraavat muuttujat ja tallenna**
##My Code
#Teams Webhook URL
$TeamsWebHookURL = 'CHANGE-TO-YOUR-WEB-HOOK-URL'
![image](https://user-images.githubusercontent.com/69797126/126144084-686f3fe1-4daf-4eec-a52a-603e3ec4ee9d.png)

# Projektin testaaminen
**Aja MyGetAzureBillingDetails Test/Run -> Run**
![image](https://user-images.githubusercontent.com/69797126/126144822-81801e6f-c369-499b-9c43-b77d0a5a53d6.png)
![image](https://user-images.githubusercontent.com/69797126/126144769-cac96f6b-7d20-4ef9-96b4-ab34effffba3.png)
![image](https://user-images.githubusercontent.com/69797126/126145045-a78b6be5-b1d1-474c-a80f-80eb6ca9bab1.png)
![image](https://user-images.githubusercontent.com/69797126/126145428-1fc79839-02a7-4235-a28c-9e65cc4097e4.png)
**Check that the functions are running and see if there are any error and check your code**
![image](https://user-images.githubusercontent.com/69797126/126145693-48087fcf-818b-4724-8911-a0e51126edbf.png)


