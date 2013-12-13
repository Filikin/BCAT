/*

Author: Eamon Kelly, Enclude
Purpose: Display happiness scale in radar plot
TODO: consider using a fieldset to define which values should be used
Called from: HappinessScalePage

getting oldest and latest 3 CRAs for the data
*/

public with sharing class HappinessScaleController 
{
	public String firstDate {get;set;}
	public String secondDate {get;set;}
	public String thirdDate {get;set;}
	public String fourthDate {get;set;}
	
	public Boolean getShowSecond() {return secondDate.length() > 0;}
	public Boolean getShowThird() {return thirdDate.length() > 0;}
	public Boolean getShowFourth() {return fourthDate.length() > 0;}
	
    Contact client=null;
    List<HappinessPointData> happypoint = new List<HappinessPointData>();
    
    public String getClientName () { return client.Name;}
     
    public List<HappinessPointData> getHappinessData() 
    {
        return happypoint;
    }

    // Wrapper classes
    public class HappinessPointData 
    {
        public String name { get; set; }
        public Integer data1 { get; set; }
        public Integer data2 { get; set; }
        public Integer data3 { get; set; }
        public Integer data4 { get; set; }

        public HappinessPointData(List<ecass01__CRA__c> CRAs, String fieldlabel, String fieldname)
        {
            try
            {
                this.name = fieldlabel;
                Integer numberOfCRAs = CRAs.size();
                Integer lastCRAIndex = CRAs.size();
                if (numberOfCRAs > 0) this.data1 = (Integer)(Decimal)(CRAs[0].get(fieldname)!=null?CRAs[0].get(fieldname):0);
                else this.data1 = 0;
                if (--lastCRAIndex > 0) this.data4 = (Integer)(Decimal)(CRAs[lastCRAIndex].get(fieldname)!=null?CRAs[lastCRAIndex].get(fieldname):0);
                else this.data4 = 0;
                if (--lastCRAIndex > 0) this.data3 = (Integer)(Decimal)(CRAs[lastCRAIndex].get(fieldname)!=null?CRAs[lastCRAIndex].get(fieldname):0);
                else this.data3 = 0;
                if (--lastCRAIndex > 0) this.data2 = (Integer)(Decimal)(CRAs[lastCRAIndex].get(fieldname)!=null?CRAs[lastCRAIndex].get(fieldname):0);
                else this.data2 = 0;
            }
            catch (Exception e)
            {
                system.debug (e);
                this.name = '';
            }
        }
    }
    
    public HappinessScaleController(ApexPages.StandardController controller)
    {
        client = (Contact)controller.getRecord();
        client = [select ID, Name from Contact where ID = :client.id];
    }
    
    public Boolean getAnyData ()
    {
        return happypoint.size() > 0;
    }
    
    public void extractData ()
    {
    	List<RecordType> CRARecordTypes = [select ID, Name from RecordType where sObjectType = 'ecass01__CRA__c'];
    	ID CRAId, CRAFTId;
    	if (CRARecordTypes[0].Name == 'CRA')
    	{
    		CRAId = CRARecordTypes[0].id;
    		CRAFTId = CRARecordTypes[1].id;
    	} 
    	else
    	{
    		CRAId = CRARecordTypes[1].id;
    		CRAFTId = CRARecordTypes[0].id;
    	}
    	Integer numCRA = [select count() from ecass01__CRA__c where ecass01__Client__c  = :client.ID and RecordTypeID=:CRAId];
    	Integer numCRAFT = [select count() from ecass01__CRA__c where ecass01__Client__c  = :client.ID and RecordTypeID=:CRAFTId];
 
     	String actualFieldSetName = 'Default_set';
 	  	if (numCRA < numCRAFT) actualFieldSetName = 'CRAFT_set';
    	
		List<Schema.FieldSetMember> happinessFields = getFields (actualFieldSetName);
    	if (happinessFields == null) return;
		List<ecass01__CRA__c> CRAs = getCRAs (happinessFields, client.Id); 
       
        if (CRAs.size() > 0)
        {
	       	for (Schema.FieldSetMember oneField: happinessFields)
        	{
            	happypoint.add (new HappinessPointData (CRAs, oneField.getLabel(), oneField.getFieldPath()));
        	}
          firstDate = CRAs[0].ecass01__Date__c.format();
          Integer lastCRAIndex = CRAs.size();
          if (--lastCRAIndex > 0) fourthDate = CRAs[lastCRAIndex].ecass01__Date__c.format();
          else fourthDate = '.';
          if (--lastCRAIndex > 0) thirdDate = CRAs[lastCRAIndex].ecass01__Date__c.format();
          else thirdDate = '.';
          if (--lastCRAIndex > 0) secondDate = CRAs[lastCRAIndex].ecass01__Date__c.format();
          else secondDate = '.';
        }
    }
    
// Helper functions
// not sure if we need CRA of CRAFT, so return the one that we have more of
 	public static List<ecass01__CRA__c> getCRAs (List<Schema.FieldSetMember> needsFields, ID clientID)
	{
		String soql = getSelectStatement (needsFields);
		soql += 'RecordTypeID FROM ecass01__CRA__c where ecass01__Client__c  = :clientID order by ecass01__Date__c asc';
		
	    List<ecass01__CRA__c> allCRAs = database.query(soql);
	    
	    if (allCRAs.size() > 0)
	    {
		    ID firstRecordType = allCRAs[0].RecordTypeID;
		    List<ecass01__CRA__c> CRAList1 = new List<ecass01__CRA__c>();
		    List<ecass01__CRA__c> CRAList2 = new List<ecass01__CRA__c>();
		    
		    for (ecass01__CRA__c oneCRA: allCRAs)
		    {
		    	if (oneCRA.RecordTypeId == firstRecordType) CRAList1.add (oneCRA);
		    	else CRAList2.add (oneCRA);
		    }
		    if (CRAList1.size() > CRAList2.size()) return CRAList1;
		    else return CRAList2;
	    }
	    else return Null;
	}
 
    public static String getSelectStatement (List<Schema.FieldSetMember> fieldList)
 	{
 		String query = 'SELECT Name, ';
        for(Schema.FieldSetMember f : fieldList) {
            query += f.getFieldPath() + ', ';
        }
        // if date is not already there, include it
        if (!query.contains(' ecass01__Date__c,')) query += 'ecass01__Date__c, ';
        query += 'Id, ';	
        return query;
 	}

    public List<Schema.FieldSetMember> getFields(String fieldSetName) 
    {
    	System.Debug ('Fieldset name is ' + fieldSetName);
    	Schema.FieldSet fs1 = Schema.SObjectType.ecass01__CRA__c.fieldSets.getMap().get(fieldSetName);
    	if (fs1 == null)
    	{
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No fieldset found for ' + fieldSetName);
	        ApexPages.addMessage(myMsg);
	        return null;
    	} 
		
    	List<Schema.FieldSetMember> allFields = fs1.getFields();
     	List<Schema.FieldSetMember> returnFields = new List<Schema.FieldSetMember>();
    	
    	for (Integer i=0; i<allFields.size(); i++)
    	{
			returnFields.add (allFields[i]);    		
    	}
    	return returnFields;
    }
    
/* Tests start here
    public static testMethod void testSampleData ()
    {
    	Contact client = new Contact (Lastname='Bloggs');
    	insert client;
    	      
    	Outcome_Star__c outcomeStar = new Outcome_Star__c (Stage__c='Admission', Motivation_and_taking_responsibility__c=2, Drug_and_alcohol_misuse__c=2, Emotional_and_mental_health__c=2, Managing_money__c=2, Managing_tenancy_and_accommodation__c=2,
                Offending__c=2, Physical_Health__c=2, Self_Care_and_living_skills__c=2, Social_networks_and_relationships__c=2, Client__c = client.id, Date_of_completion__c=system.today());
        insert outcomeStar;
    	
    	ApexPages.StandardController starControllerPage = new ApexPages.StandardController(client);
    	StarChartController star = new StarChartController (starControllerPage);
    	star.extractData();
    	system.assert (star.getAnyData());
    	star.getStarData();
    }
*/
}