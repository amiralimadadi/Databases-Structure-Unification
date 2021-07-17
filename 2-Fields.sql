--======================================= 2. Field =======================================
/* 
This file holds the query for copying the structure of fields of tables in reference database to the destination database
To execute this, you need to replace "{Base}" with your reference database name 
	and replace "{Destination}" with your destination database name
This query creates a table called "#TempBase" in tempdb, so you need access to do that.
The query contains different parts like "adding new field", "updating current fields" and 
	"updating current fields with contraints".
*/

--********** 2.1 Add Field
Begin /*AddField*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From {Base}.INFORMATION_SCHEMA.COLUMNS

Select * 
Into #TempDestination
From {Destination}.INFORMATION_SCHEMA.COLUMNS

Select Distinct TABLE_NAME,COLUMN_NAME
From	#TempBase
EXCEPT
Select Distinct TABLE_NAME,COLUMN_NAME
From	#TempDestination

Declare @tablenameAF nvarchar(50)
Declare @COLUMN_NAMEAF nvarchar(50)

Declare @rowAF int
Set @rowAF = 0

Declare cursor_AddFields Cursor For	
Select	Distinct TABLE_NAME,COLUMN_NAME
From	#TempBase
Except
Select	Distinct TABLE_NAME,COLUMN_NAME
From	#TempDestination

Open		cursor_AddFields
Fetch From	cursor_AddFields
	Into	@tablenameAF,@COLUMN_NAMEAF

While	@@Fetch_STATUS=0
	Begin
		Declare @table_nameAF SYSNAME
		Select @table_nameAF ='dbo.'+ @tablenameAF
		Declare @AddFields NVARCHAR(MAX) = ''
		Select @AddFields =
			'ALTER TABLE ' +
			@table_nameAF + CHAR(13) + 'ADD ' +
			STUFF((
					Select	CHAR(9) + ', [' + c.COLUMN_NAME + '] ' + 
							Upper(c.DATA_TYPE) + 
								Case
									When c.DATA_TYPE In ('varchar', 'char', 'varbinary', 'binary', 'text','nvarchar', 'nchar', 'ntext')
										Then '(' + Case When c.CHARACTER_MAXIMUM_LENGTH = -1 Then 'MAX' Else CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(50)) END + ')'
									When c.DATA_TYPE IN ('datetime2', 'time2', 'datetimeoffset') 
										Then '(' + CAST(c.NUMERIC_SCALE AS VARCHAR(50)) + ')'
									When c.DATA_TYPE = 'decimal' 
										Then '(' + CAST(c.NUMERIC_PRECISION AS VARCHAR(50)) + ',' + CAST(c.NUMERIC_SCALE AS VARCHAR(50)) + ')'
									Else ''
								END +
								Case
									When c.COLLATION_NAME Is Not Null Then ' Collate ' + c.COLLATION_NAME
									Else ''
								END +
								Case
									When c.IS_NULLABLE = 'YES' Then ' NULL'
									Else ' NOT NULL'
								END +
								Case
									When c.COLUMN_DEFAULT Is Not Null Then ' DEFAULT' + c.COLUMN_DEFAULT
									Else ''
								END 
							 + CHAR(13)
					From	#TempBase as c
					Where	c.TABLE_NAME = @tablenameAF And
							c.COLUMN_NAME=@COLUMN_NAMEAF
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
		PRINT @AddFields
		--EXEC sys.sp_executesql @SQL

		Fetch Next From	cursor_AddFields
		Into @tablenameAF,@COLUMN_NAMEAF
	End
Close		cursor_AddFields
Deallocate	cursor_AddFields

End /*AddField*/

--********** 2.2 Update Filed
Begin /*UpdateField*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From {Base}.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME not in (Select TABLE_NAME+COLUMN_NAME
From	{Base}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		{Base}.sys.indexes ind Inner Join 
			{Base}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Base}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			{Base}.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0  )
Select * 
Into #TempDestination
From {Destination}.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME not in (Select TABLE_NAME+COLUMN_NAME
From	{Destination}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		{Destination}.sys.indexes ind Inner Join 
			{Destination}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Destination}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			{Destination}.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0  )
Select	Distinct TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT, IS_NULLABLE,DATA_TYPE, 
		CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
From	#TempBase
Except
Select	Distinct TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT, IS_NULLABLE,DATA_TYPE,
		CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
From	#TempDestination

Declare @tablenameUF nvarchar(50)
Declare @COLUMN_NAMEUF nvarchar(50)
Declare @COLUMN_DEFAULTUF nvarchar(50)
Declare @IS_NULLABLEUF nvarchar(50)
Declare @DATA_TYPEUF nvarchar(50)
Declare @CHARACTER_MAXIMUM_LENGTHUF nvarchar(50)
Declare @NUMERIC_PRECISIONUF nvarchar(50)
Declare @NUMERIC_PRECISION_RADIXUF nvarchar(50)

Declare @rowUF int
Set @rowUF = 0

Declare			cursor_UpdateFields
Cursor For
		Select Distinct	TABLE_NAME,COLUMN_NAME,COLUMN_DEFAULT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
		From	#TempBase
		Except
		Select Distinct TABLE_NAME,COLUMN_NAME,COLUMN_DEFAULT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
		From	#TempDestination
		Open	cursor_UpdateFields
		Fetch From	cursor_UpdateFields
		Into	@tablenameUF,@COLUMN_NAMEUF,@COLUMN_DEFAULTUF,@IS_NULLABLEUF,@DATA_TYPEUF,@CHARACTER_MAXIMUM_LENGTHUF,@NUMERIC_PRECISIONUF,@NUMERIC_PRECISION_RADIXUF
		While	@@Fetch_STATUS=0
		Begin
			Declare @table_nameUF SYSNAME
			Select @table_nameUF ='dbo.'+ @tablenameUF
			Declare @UpdateFields NVARCHAR(MAX) = ''
			Select @UpdateFields =
				'ALTER TABLE ' + @table_nameUF + CHAR(13) + 'ALTER COLUMN ' +
				STUFF((
					Select	CHAR(9) + ', [' + c.COLUMN_NAME + '] ' + 
							Case
								When 0 = 1 Then 'AS ' + c.COLUMN_NAME 
								Else Upper(c.DATA_TYPE) + 
								Case
									When c.DATA_TYPE IN ('varchar', 'char', 'varbinary', 'binary', 'text','nvarchar', 'nchar', 'ntext')
										Then '(' + Case When c.CHARACTER_MAXIMUM_LENGTH = -1 Then 'MAX' Else CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(5)) END + ')'
									When c.DATA_TYPE IN ('datetime2', 'time2', 'datetimeoffset') 
										Then '(' + CAST(c.NUMERIC_SCALE AS VARCHAR(5)) + ')'
									When c.DATA_TYPE = 'decimal' 
										Then '(' + CAST(c.NUMERIC_PRECISION AS VARCHAR(5)) + ',' + CAST(c.NUMERIC_SCALE AS VARCHAR(5)) + ')'
									Else ''
								END +
								Case
									When c.COLLATION_NAME IS NOT NULL Then ' Collate ' + c.COLLATION_NAME
									Else ''
								END +
								Case
									When c.IS_NULLABLE = 'YES' Then ' NULL'
									Else ' NOT NULL'
								END +
								Case
									When c.COLUMN_DEFAULT IS NOT NULL Then ' DEFAULT' + c.COLUMN_DEFAULT
									Else ''
								END 
							END + CHAR(13)
					From	#TempBase As c
					Where	c.TABLE_NAME = @tablenameUF And
							c.COLUMN_NAME=@COLUMN_NAMEUF
							--And c.COLUMN_DEFAULT=@COLUMN_DEFAULTUF
							--And c.DATA_TYPE=@DATA_TYPEUF
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')


			PRINT @UpdateFields
			--EXEC sys.sp_executesql @SQL
			Fetch Next From	cursor_UpdateFields
			Into	@tablenameUF,@COLUMN_NAMEUF,@COLUMN_DEFAULTUF,@IS_NULLABLEUF,@DATA_TYPEUF,@CHARACTER_MAXIMUM_LENGTHUF,@NUMERIC_PRECISIONUF,@NUMERIC_PRECISION_RADIXUF
		END
		Close		cursor_UpdateFields
		Deallocate	cursor_UpdateFields
end /*UpdateField*/

--********** 2.3 UpdateField_CONSTRAINT
Begin /*UpdateField_CONSTRAINT*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From {Base}.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME  in (Select TABLE_NAME+COLUMN_NAME
From	{Base}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		{Base}.sys.indexes ind Inner Join 
			{Base}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Base}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			{Base}.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0  )
Select * 
Into #TempDestination
From {Destination}.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME  in (Select TABLE_NAME+COLUMN_NAME
From	{Destination}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		{Destination}.sys.indexes ind Inner Join 
			{Destination}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Destination}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			{Destination}.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0  )

Select	Distinct TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT, IS_NULLABLE,DATA_TYPE, 
		CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
From	#TempBase
Except
Select	Distinct TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT, IS_NULLABLE,DATA_TYPE,
		CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
From	#TempDestination

Declare @tablenameUF_c nvarchar(50)
Declare @COLUMN_NAMEUF_c nvarchar(50)
Declare @COLUMN_DEFAULTUF_c nvarchar(50)
Declare @IS_NULLABLEUF_c nvarchar(50)
Declare @DATA_TYPEUF_c nvarchar(50)
Declare @CHARACTER_MAXIMUM_LENGTHUF_c nvarchar(50)
Declare @NUMERIC_PRECISIONUF_c nvarchar(50)
Declare @NUMERIC_PRECISION_RADIXUF_c nvarchar(50)

Declare @rowUF_c int
Set @rowUF_c = 0

Declare			cursor_UpdateFields_c
Cursor For
		Select Distinct	TABLE_NAME,COLUMN_NAME,COLUMN_DEFAULT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
		From	#TempBase
		Except
		Select Distinct TABLE_NAME,COLUMN_NAME,COLUMN_DEFAULT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX
		From	#TempDestination
		Open	cursor_UpdateFields_c
		Fetch From	cursor_UpdateFields_c
		Into	@tablenameUF_c,@COLUMN_NAMEUF_c,@COLUMN_DEFAULTUF_c,@IS_NULLABLEUF_c,@DATA_TYPEUF_c,@CHARACTER_MAXIMUM_LENGTHUF_c,@NUMERIC_PRECISIONUF_c,@NUMERIC_PRECISION_RADIXUF_c
		While	@@Fetch_STATUS=0
		Begin
			Declare @table_nameUF_c SYSNAME
			Select @table_nameUF_c ='dbo.'+ @tablenameUF_c
			Declare @UpdateFields_c NVARCHAR(MAX) = ''
			Select @UpdateFields_c =@tablenameUF_c+char(13)+
				STUFF((
					Select	char(13)+ ', [' + c.COLUMN_NAME + '] '  + CHAR(13)
					From	#TempBase As c
					Where	c.TABLE_NAME = @tablenameUF_c And
							c.COLUMN_NAME=@COLUMN_NAMEUF_c
							--And c.COLUMN_DEFAULT=@COLUMN_DEFAULTUF
							--And c.DATA_TYPE=@DATA_TYPEUF
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(20) + ' ')


			PRINT @UpdateFields_c
			--EXEC sys.sp_executesql @SQL
			Fetch Next From	cursor_UpdateFields_c
			Into	@tablenameUF_c,@COLUMN_NAMEUF_c,@COLUMN_DEFAULTUF_c,@IS_NULLABLEUF_c,@DATA_TYPEUF_c,@CHARACTER_MAXIMUM_LENGTHUF_c,@NUMERIC_PRECISIONUF_c,@NUMERIC_PRECISION_RADIXUF_c
		END
		Close		cursor_UpdateFields_c
		Deallocate	cursor_UpdateFields_c
end /*UpdateField_CONSTRAINT*/