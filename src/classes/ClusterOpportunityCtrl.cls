public with sharing class ClusterOpportunityCtrl {

	private final String apiKey = 'your api key';
	private Opportunity record;
	public String screenMsg {get;set;}

	public ClusterOpportunityCtrl(ApexPages.StandardController stdCtrl) {
		this.record = (Opportunity)stdCtrl.getRecord();
	}

	public PageReference cluster() {
		Opportunity record = [SELECT Amount,
		                             Type,
		                             LeadSource,
		                             Owner.Name
		                        FROM Opportunity 
		                       WHERE Id =: record.Id];
		Map<String, Object> fieldsToValue = record.getPopulatedFieldsAsMap();
		List<String> columnNames  = new List<String>();
		List<String> values = new List<String>();
		
		for(String fieldName : fieldsToValue.keySet()){
			if(fieldName == 'Id' || fieldName == 'OwnerId') {
				// requestのIFに無いので除外
				continue;
			}
			System.debug('@@@'+fieldName);
			if(fieldName == 'Owner.Name') {
				// AzureML側の項目名をOwnerにしているので置換
				fieldName = 'Owner';
			}
			columnNames.add(fieldName);
			values.add(String.valueOf(fieldsToValue.get(fieldName)));
		}
		
		String requestBody = createRequestJson(columnNames, values);
		HttpRequest req = new HttpRequest();
		req.setEndpoint('yourEndPointURL');
		req.setMethod('POST');

		req.setHeader('Authorization', 'Bearer ' + apiKey);
		req.setHeader('Content-Length', String.valueOf(requestBody.length()));
		req.setHeader('Content-Type', 'application/json');
		req.setBody(requestBody);

		Http h = new Http();
		HttpResponse res = h.send(req);
		System.debug(res.getBody());

		if(res.getStatusCode() == 200){
			screenMsg = res.getBody();
		} else {
			screenMsg = 'エラー' + res.getBody();
		}
		return null;
	}
	
	private String createRequestJson(List<String> columnName, List<String> oneRecVals){
		List<List<String>> values = new List<List<String>>();
		values.add(oneRecVals);

		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
		gen.writeFieldName('Inputs');
		gen.writeStartObject();
		gen.writeFieldName('input1');
		gen.writeStartObject();
		gen.writeObjectField('ColumnNames', columnName);
		gen.writeObjectField('Values', values);
		gen.writeEndObject();
		gen.writeEndObject();
		gen.writeFieldName('GlobalParameters');
		gen.writeStartObject();
		gen.writeEndObject();
		gen.writeEndObject();

		String pretty = gen.getAsString();
		return pretty;
	}
}
