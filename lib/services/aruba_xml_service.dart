import 'dart:io';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_flow_pro/database/database_helper.dart';

class ArubaXmlService {
  static Future<File?> generateAndDownload(Map<String, dynamic> invoice, Map<String, dynamic> customer) async {
    try {
      final builder = XmlBuilder();
      
      final prefs = await SharedPreferences.getInstance();
      final companyVat = prefs.getString('company_vat') ?? '01234567890';
      final companyName = prefs.getString('company_name') ?? 'La Tua Azienda S.r.l. (Da Configurare)';
      final companyAddress = prefs.getString('company_address') ?? 'Via Placeholder 1';
      final companyZip = prefs.getString('company_zip') ?? '00100';
      final companyCity = prefs.getString('company_city') ?? 'Roma';
      final companyProvince = prefs.getString('company_province') ?? 'RM';
      final companyRegime = prefs.getString('company_regime') ?? 'RF01';
      
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      
      // I namespace sono fondamentali per FatturaPA
      builder.element('p:FatturaElettronica', attributes: {
        'versione': 'FPR12',
        'xmlns:ds': 'http://www.w3.org/2000/09/xmldsig#',
        'xmlns:p': 'http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2',
        'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation': 'http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2 http://www.fatturapa.gov.it/export/fatturazione/sdi/fatturapa/v1.2/Schema_del_file_xml_FatturaPA_versione_1.2.xsd'
      }, nest: () {
        
        // 1. HEADER (FatturaElettronicaHeader)
        builder.element('FatturaElettronicaHeader', nest: () {
          
          // Dati Trasmissione
          builder.element('DatiTrasmissione', nest: () {
            builder.element('IdTrasmittente', nest: () {
              builder.element('IdPaese', nest: 'IT');
              builder.element('IdCodice', nest: companyVat); 
            });
            builder.element('ProgressivoInvio', nest: invoice['id']?.toString() ?? '1');
            builder.element('FormatoTrasmissione', nest: 'FPR12');
            builder.element('CodiceDestinatario', nest: '0000000'); // Default per privati, o recuperabile dal cliente
          });
          
          // Cedente Prestatore (Dati di chi emette fattura)
          builder.element('CedentePrestatore', nest: () {
            builder.element('DatiAnagrafici', nest: () {
              builder.element('IdFiscaleIVA', nest: () {
                builder.element('IdPaese', nest: 'IT');
                builder.element('IdCodice', nest: companyVat);
              });
              builder.element('Anagrafica', nest: () {
                builder.element('Denominazione', nest: companyName);
              });
              builder.element('RegimeFiscale', nest: companyRegime); // Ordinario
            });
            builder.element('Sede', nest: () {
              builder.element('Indirizzo', nest: companyAddress);
              builder.element('CAP', nest: companyZip);
              builder.element('Comune', nest: companyCity);
              builder.element('Provincia', nest: companyProvince);
              builder.element('Nazione', nest: 'IT');
            });
          });
          
          // Cessionario Committente (Dati Cliente)
          builder.element('CessionarioCommittente', nest: () {
            builder.element('DatiAnagrafici', nest: () {
              // Se il cliente ha la partita IVA o se non ce l'ha, gestiamo il fallback
              // Per semplicità mettiamo il Codice Fiscale (se disponibile, altrimenti mettiamo 00000000000)
              final vatNumber = customer['vat_number']?.toString().replaceAll(' ', '');
              final taxCode = customer['tax_code']?.toString().replaceAll(' ', '');
              
              if (vatNumber != null && vatNumber.isNotEmpty && vatNumber.length >= 11) {
                builder.element('IdFiscaleIVA', nest: () {
                  builder.element('IdPaese', nest: 'IT'); // Si assume IT per default
                  builder.element('IdCodice', nest: vatNumber);
                });
              } else if (taxCode != null && taxCode.isNotEmpty) {
                builder.element('CodiceFiscale', nest: taxCode);
              } else {
                 // Fallback necessario per XML valido, l'utente dovrà correggerlo in Aruba
                 builder.element('CodiceFiscale', nest: 'XXXXXXXXXXXXXXXX');
              }
              
              builder.element('Anagrafica', nest: () {
                 if (customer['company'] != null && customer['company'].toString().isNotEmpty) {
                    builder.element('Denominazione', nest: customer['company'].toString());
                 } else {
                    builder.element('Nome', nest: customer['name'].toString().split(' ').first);
                    builder.element('Cognome', nest: customer['name'].toString().contains(' ') 
                        ? customer['name'].toString().split(' ').sublist(1).join(' ') 
                        : 'Sconosciuto');
                 }
              });
            });
            
            builder.element('Sede', nest: () {
              builder.element('Indirizzo', nest: customer['address'] ?? 'Indirizzo Sconosciuto');
              builder.element('CAP', nest: customer['zip_code'] ?? '00000');
              builder.element('Comune', nest: customer['city'] ?? 'Comune Sconosciuto');
              builder.element('Provincia', nest: customer['province'] ?? 'XX'); // Deve essere 2 lettere
              builder.element('Nazione', nest: 'IT');
            });
          });
        });
        
        // 2. BODY (FatturaElettronicaBody)
        builder.element('FatturaElettronicaBody', nest: () {
          
          // Dati Generali
          builder.element('DatiGenerali', nest: () {
            builder.element('DatiGeneraliDocumento', nest: () {
              builder.element('TipoDocumento', nest: 'TD01'); // Fattura standard
              builder.element('Divisa', nest: 'EUR');
              
              final dateStr = invoice['date'] ?? DateTime.now().toIso8601String().split('T').first;
              builder.element('Data', nest: dateStr);
              builder.element('Numero', nest: invoice['number']?.toString() ?? '1');
              builder.element('ImportoTotaleDocumento', nest: invoice['total']?.toString() ?? '0.00');
            });
          });
          
          // Dati Beni Servizi
          builder.element('DatiBeniServizi', nest: () {
            
            // In un caso reale, qui andrebbero le righe (DettaglioLinee) della fattura
            // Siccome il db attuale ha un totale forfettario, creiamo un'unica linea
            builder.element('DettaglioLinee', nest: () {
              builder.element('NumeroLinea', nest: '1');
              builder.element('Descrizione', nest: 'Servizi o Beni - Fattura N. ${invoice['number'] ?? '1'}');
              builder.element('PrezzoUnitario', nest: invoice['total']?.toString() ?? '0.00');
              builder.element('PrezzoTotale', nest: invoice['total']?.toString() ?? '0.00');
              builder.element('AliquotaIVA', nest: '22.00'); // Default
            });
            
            // Dati di riepilogo per aliquota IVA
            builder.element('DatiRiepilogo', nest: () {
              builder.element('AliquotaIVA', nest: '22.00');
              builder.element('ImponibileImporto', nest: invoice['total']?.toString() ?? '0.00');
              builder.element('Imposta', nest: '0.00'); // Calcolo da adeguare in un caso reale
              builder.element('EsigibilitaIVA', nest: 'I'); // I = Immediata
            });
            
          });
          
          // Dati Pagamento
          builder.element('DatiPagamento', nest: () {
            builder.element('CondizioniPagamento', nest: 'TP02'); // Pagamento a rate/completo
            builder.element('DettaglioPagamento', nest: () {
              builder.element('ModalitaPagamento', nest: 'MP05'); // Bonifico (default)
              builder.element('ImportoPagamento', nest: invoice['total']?.toString() ?? '0.00');
            });
          });
          
        });
      });
      
      final document = builder.buildDocument();
      final xmlString = document.toXmlString(pretty: true, indent: '  ');
      
      // Salva nel file system
      Directory? directory;
      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory(); // Oppure getExternalStorageDirectory() su Android per "Download"
      } else {
        directory = await getDownloadsDirectory();
      }
      
      if (directory == null) return null;
      
      final fileName = 'IT${companyVat}_FPA${invoice['number'] ?? invoice['id'] ?? '1'}.xml';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(xmlString);
      return file;
      
    } catch (e) {
      print('Errore generazione XML: $e');
      return null;
    }
  }
}
