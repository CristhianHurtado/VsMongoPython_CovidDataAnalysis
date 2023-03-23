
               use project
               
            --Creating aux table
            select code, province, casesJson
            into AUX
            FROM OPENROWSET (BULK 'C:\project_files\new_covid_cases.json', SINGLE_CLOB) as tmp
            cross apply openjson(bulkcolumn)
            with
            (
	            code varchar(3),
	            province varchar(100),
	            casesJson nvarchar(max) as json
            )
            
            --Creating cases table with aux table
            select identity(bigint, 1, 1) as casesID, cases, convert(varchar, date_report, 3) as [date_report], cumulative_cases, code as 'provinceCode'
            into CASES
            from AUX
            cross apply openjson(casesJson)
            with
            (
	            cases int ,
	            date_report varchar(50),
	            cumulative_cases int
            )
            
                 --Creating province table
                 declare @covidJson nvarchar(max)
                 SELECT @covidJson = BulkColumn
                 FROM OPENROWSET (BULK 'C:\project_files\new_covid_cases.json', SINGLE_CLOB) as j

                 select *
                 into PROVINCES
                 from openjson(@covidJson)
                 with(
	                 provinceCode varchar(3) '$.code',
	                 provinceName varchar(100) '$.province'
                 )
                 
                          --Changing string date to datetime
                          update CASES
                          set [date_report] = TRY_CONVERT(datetime, [date_report], 103)

                          alter table CASES
                          alter column date_report datetime
                          
                     --Adding constraints
                     alter table PROVINCES
                     alter column provinceCode varchar(3)not null
                     
                     alter table PROVINCES
                     add constraint pk_PROVINCE_provinceCode primary key(provinceCode)

                     alter table CASES
                     add constraint fk_CASES_provinceCode foreign key(provinceCode) references PROVINCES(provinceCode)

                     alter table CASES
                     add constraint pk_CASES_cases primary key(casesID)
                     