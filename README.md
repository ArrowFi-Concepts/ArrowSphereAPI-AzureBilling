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
  - 
