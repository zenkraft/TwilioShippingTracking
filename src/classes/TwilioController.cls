public with sharing class TwilioController {

	private enum StatusEnum {
		CASE_NOT_FOUND,
		SHIPMENT_NOT_FOUND,
		STATUS_IS_EMPTY
	}

	public String responseXML {get;set;}
	private String callingStatus;
	private String digits;

	private String sayMessage;
	private StatusEnum statusMessage;

	public TwilioController() {
		System.debug('all parameters:' + ApexPages.currentPage().getParameters());
		// read parameters
		this.callingStatus = ApexPages.currentPage().getParameters().get('CALLSTATUS');
		this.digits = ApexPages.currentPage().getParameters().get('DIGITS');
	}

	public void init() {


		Xmlstreamwriter xmlResponseWritter = new Xmlstreamwriter();
		// Boolean isUsed = false;
		// send basic information
		if (this.callingStatus == 'ringing') {
			xmlResponseWritter.writeStartElement(null,'Response',null);
				xmlResponseWritter.writeStartElement(null,'Gather',null);
					xmlResponseWritter.writeAttribute(null,null,'timeout', '10');
					xmlResponseWritter.writeAttribute(null,null,'finishOnKey', '*');

					// say element
					xmlResponseWritter.writeStartElement(null,'Say',null);
						xmlResponseWritter.writeCharacters('Please enter your case number and then press star');
					xmlResponseWritter.writeEndElement();

				xmlResponseWritter.writeEndElement(); // Gather
			xmlResponseWritter.writeEndElement(); // Response

			responseXML = xmlResponseWritter.getXmlString();	
			// isUsed = true;
		}
		// find case number
		if (callingStatus == 'in-progress' && this.digits != null && !String.isEmpty(this.digits)) {
			findStatusMessage();
			// try again
			if (statusMessage == StatusEnum.CASE_NOT_FOUND) {
				xmlResponseWritter.writeStartElement(null,'Response',null);
					xmlResponseWritter.writeStartElement(null,'Gather',null);
						xmlResponseWritter.writeAttribute(null,null,'timeout', '10');
						xmlResponseWritter.writeAttribute(null,null,'finishOnKey', '*');

						// say element
						xmlResponseWritter.writeStartElement(null,'Say',null);
							xmlResponseWritter.writeCharacters('Sorry, that case number was not found. Please try again');
						xmlResponseWritter.writeEndElement();

					xmlResponseWritter.writeEndElement(); // Gather
				xmlResponseWritter.writeEndElement(); // Response
			} else { // say message and finish call
				xmlResponseWritter.writeStartElement(null,'Response',null);
					xmlResponseWritter.writeStartElement(null,'Gather',null);
						// say element
						xmlResponseWritter.writeStartElement(null,'Say',null);
							xmlResponseWritter.writeCharacters(sayMessage);
						xmlResponseWritter.writeEndElement();
					xmlResponseWritter.writeEndElement(); // Gather
				xmlResponseWritter.writeEndElement(); // Response
			}

			responseXML = xmlResponseWritter.getXmlString();

			// isUsed = true;
		}

		// for debug in Twilio site

		// if (!isUsed) {
		// 	xmlResponseWritter.writeStartElement(null,'Response',null);
		// 		xmlResponseWritter.writeStartElement(null,'DEBUG',null);
		// 			xmlResponseWritter.writeCharacters(callingStatus + '|' + digits);
		// 		xmlResponseWritter.writeEndElement();
		// 	xmlResponseWritter.writeEndElement(); // Response

		// 	responseXML = xmlResponseWritter.getXmlString();
		// }


	}

	private void findStatusMessage() {
		Case foundCase = null;
		try {
			foundCase = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber =:this.digits];	
		} catch (Exception e) {
			System.debug(LoggingLevel.DEBUG, '#### (TwilioController::findStatusMessage) Exception occured: ' + e.getTypeName() + ': ' + e.getMessage());
			foundCase = null;
		}

		if (foundCase == null) {
			this.statusMessage = StatusEnum.CASE_NOT_FOUND;
			return;
		}
		// load the latest shipment and read out the Current Description
		zkfedex__Shipment__c shipment = null;
		try {
			shipment = [SELECT Id, zkfedex__StatusDescription__c FROM zkfedex__Shipment__c WHERE Case__c = :foundCase.Id ORDER BY CreatedDate DESC LIMIT 1];	
		} catch (Exception e) {
			System.debug(LoggingLevel.DEBUG, '#### (TwilioController::findStatusMessage) Exception occured: ' + e.getTypeName() + ': ' + e.getMessage());
			shipment = null;
		}

		if (shipment == null) {
			this.sayMessage = 'Shipment not found. Goodbye!';
			this.statusMessage = StatusEnum.SHIPMENT_NOT_FOUND;
			return;
		}

		// check empty status description
		if (shipment.zkfedex__StatusDescription__c == null || String.isEmpty(shipment.zkfedex__StatusDescription__c)) {
			this.sayMessage = 'We don\'t have a current tracking status at the moment, please try again later.';
			this.statusMessage = StatusEnum.STATUS_IS_EMPTY;
			return;
		}

		this.sayMessage = shipment.zkfedex__StatusDescription__c;
		
	}
    
}