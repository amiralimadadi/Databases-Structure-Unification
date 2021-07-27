--======================================= 1. Table =======================================
--********** 1.1 Add Table
Begin /*AddTable*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select * 
Into	#TempBase
From	Watch.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME Not In (Select TABLE_NAME From Watch.INFORMATION_SCHEMA.VIEWS)

Select	* 
Into	#TempDestination
From	WatchBU.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME Not In (Select TABLE_NAME From WatchBU.INFORMATION_SCHEMA.VIEWS)

Select Distinct TABLE_NAME
From	#TempBase
Where	TABLE_NAME not in(Select TABLE_NAME From #TempDestination) 
Declare @tablename nvarchar(50)
Declare @row int
Set @row = 0

Declare Cursor_AddTable Cursor For
Select	Distinct TABLE_NAME
From	#TempBase
Where	TABLE_NAME Not In (Select TABLE_NAME From #TempDestination)

Open	Cursor_AddTable
Fetch From Cursor_AddTable
	Into	@tablename

While	@@Fetch_STATUS=0
	Begin
		Declare @table_name SysName
		Select @table_name ='dbo.'+ @tablename
		Declare @AddTable NvarChar(Max) = ''

		Select @AddTable =
			'Create Table ' + @table_name + CHAR(13) + '(' + CHAR(13) +
			STUFF((
					Select	CHAR(9) + ', [' + c.COLUMN_NAME + '] ' + 
							Upper(c.DATA_TYPE) + 
							Case
								When c.DATA_TYPE IN ('varchar', 'char', 'varbinary', 'binary', 'text','nvarchar', 'nchar', 'ntext')
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
								When c.COLUMN_DEFAULT IS NOT NULL Then ' DEFAULT' + c.COLUMN_DEFAULT
								Else ''
							END 
							 + CHAR(13)
					From	#TempBase As c
					Where	c.TABLE_NAME = @tablename
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')+')'

		PRINT @AddTable
		--EXEC sys.sp_executesql @AddTable

		Fetch Next From	Cursor_AddTable
		Into @tablename
	End
Close		Cursor_AddTable
Deallocate	Cursor_AddTable
End /*AddTable*/

--********** 1.2 Update Table
Begin /*Update Table*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
End /*Update Table*/

--********** 1.3 Delete Table
Begin /*DeleteTable*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select	* 
Into	#TempBase
From	Watch.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME not in (Select TABLE_NAME From Watch.INFORMATION_SCHEMA.VIEWS)

Select	* 
Into	#TempDestination
From	WatchBU.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME not in (Select TABLE_NAME From WatchBU.INFORMATION_SCHEMA.VIEWS)

Select	Distinct TABLE_NAME
From	#TempDestination
Where	TABLE_NAME not in(Select TABLE_NAME From #TempBase) 

Declare @tablenameTD nvarchar(50)
Declare @rowTD int
Set @rowTD = 0

Declare	Cursor_DeleteTable Cursor For
Select	Distinct TABLE_NAME
From	#TempDestination
Where	TABLE_NAME Not In (Select TABLE_NAME From #TempBase)

Open		Cursor_DeleteTable
Fetch From	Cursor_DeleteTable
	Into	@tablenameTD

While	@@Fetch_STATUS=0
	Begin
			Declare @table_nameTD SYSNAME
			Select @table_nameTD ='dbo.'+ @tablenameTD

			Declare @Deletetable NVARCHAR(MAX) = ''
			Select @Deletetable = 'Drop TABLE ' + @table_nameTD
			Print @Deletetable
			--EXEC sys.sp_executesql @AddTable
			Fetch Next From	Cursor_DeleteTable
			Into @tablenameTD
	End
Close		Cursor_DeleteTable
Deallocate	Cursor_DeleteTable

End /*DeleteTable*/
--======================================= 2. Field =======================================
--********** 2.1 Add Filed
Begin /*AddField*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From Watch.INFORMATION_SCHEMA.COLUMNS

Select * 
Into #TempDestination
From WatchBU.INFORMATION_SCHEMA.COLUMNS

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
From Watch.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME not in (Select TABLE_NAME+COLUMN_NAME
From	Watch.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		Watch.sys.indexes ind Inner Join 
			Watch.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			Watch.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			Watch.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0  )
Select * 
Into #TempDestination
From WatchBU.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME not in (Select TABLE_NAME+COLUMN_NAME
From	WatchBU.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		WatchBU.sys.indexes ind Inner Join 
			WatchBU.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			WatchBU.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			WatchBU.sys.tables t On ind.object_id = t.object_id 
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

Begin /*UpdateField_CONSTRAINT*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From Watch.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME  in (Select TABLE_NAME+COLUMN_NAME
From	Watch.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		Watch.sys.indexes ind Inner Join 
			Watch.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			Watch.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			Watch.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0  )
Select * 
Into #TempDestination
From WatchBU.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME+COLUMN_NAME  in (Select TABLE_NAME+COLUMN_NAME
From	WatchBU.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
union 
Select		t.name+col.name
From		WatchBU.sys.indexes ind Inner Join 
			WatchBU.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			WatchBU.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			WatchBU.sys.tables t On ind.object_id = t.object_id 
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

--********** 2.3 Delete Filed

--======================================= 3. Viw =======================================
--********** 3.1 Add Viwe

Begin /*AddViews*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From Watch.INFORMATION_SCHEMA.VIEWS

Select * 
Into #TempDestination
From WatchBU.INFORMATION_SCHEMA.VIEWS

Select Distinct TABLE_NAME
From	#TempBase
Where	TABLE_NAME Not In (Select TABLE_NAME From #TempDestination)

Declare @tablenameAV nvarchar(50)
Declare @rowAV int
Set @rowAV = 0

Declare Cursor_AddViews Cursor For
Select Distinct TABLE_NAME
From	#TempBase
Where	TABLE_NAME Not In (Select TABLE_NAME From #TempDestination)
		
Open		Cursor_AddViews
Fetch From	Cursor_AddViews
	Into	@tablenameAV

While	@@Fetch_STATUS=0
	Begin
		Declare @table_nameAV SYSNAME
		Select @table_nameAV ='dbo.'+ @tablenameAV
		Declare @AddViews NVARCHAR(MAX) = ''
		Select @AddViews = c.VIEW_DEFINITION
		From #TempBase as c
		Where c.TABLE_NAME = @tablenameAV
		PRINT @AddViews
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_AddViews
		Into @tablenameAV
	END
Close		Cursor_AddViews
Deallocate	Cursor_AddViews
End /*AddViews*/

--********** 3.2 Update Viwe
Begin /*UpdateViews*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
If Object_ID ('tempdb.dbo.#TempCursor', 'U') Is Not Null Drop Table #TempCursor;

Select	c.*, v.VIEW_DEFINITION 
Into	#TempBase
From	Watch.INFORMATION_SCHEMA.VIEWS as v join
		Watch.INFORMATION_SCHEMA.VIEW_COLUMN_USAGE as c on v.TABLE_NAME=c.VIEW_NAME

Select	c.*,v.VIEW_DEFINITION 
Into	#TempDestination
From	WatchBU.INFORMATION_SCHEMA.VIEWS as v join
		WatchBU.INFORMATION_SCHEMA.VIEW_COLUMN_USAGE as c on v.TABLE_NAME=c.VIEW_NAME
SELECT * INTO #TempCursor FROM (
Select	Distinct TABLE_NAME,COLUMN_NAME,VIEW_NAME
From	#TempBase
Except
Select	Distinct TABLE_NAME,COLUMN_NAME,VIEW_NAME
From	#TempDestination
union
Select	Distinct TABLE_NAME,COLUMN_NAME,VIEW_NAME
From	#TempDestination
Except
Select	Distinct TABLE_NAME,COLUMN_NAME,VIEW_NAME
From	#TempBase)as tmp
Declare @ViewnameUV nvarchar(50)
Declare @TABLE_NAMEUV nvarchar(50)
Declare @COLUMN_NAMEUV nvarchar(50)
Declare @rowUV int
Set @rowUV = 0

Declare Cursor_UpdateViews Cursor For
select Distinct VIEW_NAME from #TempCursor
Open		Cursor_UpdateViews
Fetch From	Cursor_UpdateViews
	Into	@ViewnameUV

While	@@Fetch_STATUS=0
	Begin
		Declare @View_nameUV SYSNAME
		Select @View_nameUV ='dbo.'+ @ViewnameUV
		Declare @UpdateViews NVARCHAR(MAX) = ''
		Select @UpdateViews =
			'DROP VIEW '+@View_nameUV
			+' '+ c.VIEW_DEFINITION
		From #TempBase as c
		Where c.VIEW_NAME = @ViewnameUV
		
		PRINT @UpdateViews
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_UpdateViews
		Into @ViewnameUV
	End
Close		Cursor_UpdateViews
Deallocate	Cursor_UpdateViews

End /*UpdateViews*/

--********** 3.3 Delete Viwe
Begin /*DeleteViews*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select * 
Into #TempBase
From Watch.INFORMATION_SCHEMA.VIEWS

Select * 
Into #TempDestination
From WatchBU.INFORMATION_SCHEMA.VIEWS

Select Distinct TABLE_NAME
From	#TempDestination
Except
Select Distinct TABLE_NAME
From	#TempBase

Declare @TABLE_NAMEDV nvarchar(50)
Declare @rowDV int
Set @rowDV = 0

Declare Cursor_DeleteViews Cursor For
Select Distinct TABLE_NAME
From	#TempDestination
Except
Select Distinct TABLE_NAME
From	#TempBase

Open		Cursor_DeleteViews
Fetch From	Cursor_DeleteViews
	Into	@TABLE_NAMEDV

While	@@Fetch_STATUS=0
	Begin
		Declare @View_nameDV SYSNAME
		Select @View_nameDV ='dbo.'+ @TABLE_NAMEDV
		Declare @DeleteViews NVARCHAR(MAX) = ''
		Select @DeleteViews = 'DROP VIEW '+@View_nameDV
		
		PRINT @DeleteViews
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_DeleteViews
		Into @TABLE_NAMEDV
	END
Close		Cursor_DeleteViews
Deallocate	Cursor_DeleteViews

End /*DeleteViews*/
--======================================= 4. Primary Key =======================================

--********** 4.1 Add PK
Begin /*AddPK*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select c.TABLE_CATALOG,c.TABLE_NAME,c.CONSTRAINT_NAME,c.COLUMN_NAME 
Into	#TempBase
From	Watch.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as c join
		Watch.INFORMATION_SCHEMA.TABLE_CONSTRAINTS as t
			on c.CONSTRAINT_NAME=t.CONSTRAINT_NAME
Where	CONSTRAINT_TYPE='PRIMARY KEY'

Select	c.TABLE_CATALOG,c.TABLE_NAME,c.CONSTRAINT_NAME,c.COLUMN_NAME
Into	#TempDestination
From	WatchBu.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as c join
		WatchBu.INFORMATION_SCHEMA.TABLE_CONSTRAINTS as t
			on c.CONSTRAINT_NAME=t.CONSTRAINT_NAME
Where	CONSTRAINT_TYPE='PRIMARY KEY'
 
Select	*
From	#TempBase
Where	CONSTRAINT_NAME NOT IN
			(Select Distinct CONSTRAINT_NAME From #TempDestination)

Declare @tablenameAPK nvarchar(50)
Declare @CONSTRAINT_NAMEAPK nvarchar(50)
Declare @rowAPK int
Set @rowAPK = 0
Declare Cursor_AddPK Cursor For
Select	Distinct TABLE_NAME,CONSTRAINT_NAME
From	#TempBase
Where	TABLE_NAME Not In (Select TABLE_NAME From #TempDestination)

Open		Cursor_AddPK
Fetch From	Cursor_AddPK
	Into	@tablenameAPK,@CONSTRAINT_NAMEAPK

While	@@Fetch_STATUS=0
	Begin
		Declare @table_nameAPK SYSNAME
		Select @table_nameAPK ='dbo.'+ @tablenameAPK 
		Declare @AddPK NVARCHAR(MAX) = ''
		
		Select	@AddPK = 'ALTER TABLE ' + @table_nameAPK + ' ADD PRIMARY KEY ('+c.COLUMN_NAME+');'
		From	#TempBase as c
		Where c.CONSTRAINT_NAME = @CONSTRAINT_NAMEAPK
		
		PRINT @AddPK
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_AddPK
		Into	@tablenameAPK,@CONSTRAINT_NAMEAPK
	END
Close		Cursor_AddPK
Deallocate	Cursor_AddPK

End /*AddPK*/

--********** 4.2 Delete PK
Begin /*DeletePK*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select c.TABLE_CATALOG,c.TABLE_NAME,c.CONSTRAINT_NAME,c.COLUMN_NAME 
Into #TempBase
From	Watch.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as c join
		Watch.INFORMATION_SCHEMA.TABLE_CONSTRAINTS as t
			on c.CONSTRAINT_NAME=t.CONSTRAINT_NAME
Where	CONSTRAINT_TYPE='PRIMARY KEY'

Select	c.TABLE_CATALOG,c.TABLE_NAME,c.CONSTRAINT_NAME,c.COLUMN_NAME
Into	#TempDestination
From	WatchBu.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as c join
		WatchBu.INFORMATION_SCHEMA.TABLE_CONSTRAINTS as t
			on c.CONSTRAINT_NAME=t.CONSTRAINT_NAME
Where	CONSTRAINT_TYPE='PRIMARY KEY'

Select	*
From	#TempDestination
Where	CONSTRAINT_NAME NOT IN
			(Select Distinct CONSTRAINT_NAME From #TempBase)

Declare @tablenameDPK nvarchar(50)
Declare @CONSTRAINT_NAMEDPK nvarchar(50)
Declare @rowDPK int
Set @rowDPK = 0
Declare Cursor_DeletePK Cursor For
Select	Distinct TABLE_NAME,CONSTRAINT_NAME
From	#TempDestination
Where	CONSTRAINT_NAME Not In 
			(Select CONSTRAINT_NAME From #TempBase)

Open		Cursor_DeletePK
Fetch From	Cursor_DeletePK
	Into	@tablenameDPK,@CONSTRAINT_NAMEDPK

While	@@Fetch_STATUS=0
	Begin
		Declare @table_nameDPK SYSNAME
		Select @table_nameDPK ='dbo.'+ @tablenameDPK 
		Declare @DeletePK NVARCHAR(MAX) = ''
		Select	@DeletePK =
				'ALTER TABLE ' + @table_nameDPK + ' DROP CONSTRAINT '+c.CONSTRAINT_NAME+';'
		From	#TempDestination as c
		Where	c.CONSTRAINT_NAME = @CONSTRAINT_NAMEDPK
		
		PRINT @DeletePK
		--EXEC sys.sp_executesql @AddTable
		
		Fetch Next From	Cursor_DeletePK
		Into @tablenameDPK,@CONSTRAINT_NAMEDPK
	END
Close		Cursor_DeletePK
Deallocate	Cursor_DeletePK

end /*DeletePK*/
--======================================= 5. Foreign Key =======================================
--********** 5.1 Add FK
Begin /*AddFK*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempBase
From	Watch.sys.foreign_key_columns fkc Inner Join
		Watch.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		Watch.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		Watch.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		Watch.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		Watch.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		Watch.sys.columns col2 On	col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id

Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempDestination
From	WatchBu.sys.foreign_key_columns fkc Inner Join
		WatchBu.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		WatchBu.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		WatchBu.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		WatchBu.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		WatchBu.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		WatchBu.sys.columns col2 On col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id

Select	*
From	#TempBase
Where	FK_NAME Not In
		(Select Distinct FK_NAME From #TempDestination)

Declare @FknameAFK nvarchar(50)
Declare @TableNameAFK nvarchar(50)

Declare @rowAFK int
Set @rowAFK = 0

Declare Cursor_AddFK Cursor For
Select	Distinct FK_NAME,[table]
From	#TempBase
Where	FK_NAME Not In
			(Select FK_NAME From #TempDestination)

Open		Cursor_AddFK
Fetch From	Cursor_AddFK
	Into	@FknameAFK,@TableNameAFK

While	@@Fetch_STATUS=0
	Begin
		Declare @AddFK NVARCHAR(MAX) = ''
		Select	@AddFK =
					'ALTER TABLE ' + @TableNameAFK+
					' ADD CONSTRAINT '+ @FknameAFK +' FOREIGN KEY ('+ c.[column]+
					') REFERENCES '+c.referenced_table+'('+c.referenced_column+')'
		From	#TempBase as c
		Where	c.[table] = @TableNameAFK And
				c.FK_NAME=@FknameAFK
		
		PRINT @AddFK
		--EXEC sys.sp_executesql @AddTable
		
		Fetch Next From	Cursor_AddFK
		Into @FknameAFK,@TableNameAFK
	END
Close		Cursor_AddFK
Deallocate	Cursor_AddFK
End /*AddFK*/

--********** 5.2 Delete FK
Begin /*DeleteFK*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempBase
From	Watch.sys.foreign_key_columns fkc Inner Join
		Watch.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		Watch.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		Watch.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		Watch.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		Watch.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		Watch.sys.columns col2 On	col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id
Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempDestination
From	WatchBu.sys.foreign_key_columns fkc Inner Join
		WatchBu.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		WatchBu.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		WatchBu.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		WatchBu.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		WatchBu.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		WatchBu.sys.columns col2 On	col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id

Select	*
From	#TempDestination
Where	FK_NAME Not In
			(Select Distinct FK_NAME From #TempBase)

Declare @FknameDFK nvarchar(50)
Declare @TableNameDFK nvarchar(50)

Declare @rowDFK int
Set @rowDFK = 0
Declare Cursor_DeleteFK Cursor For
Select	Distinct FK_NAME,[table]
From	#TempDestination
Where	FK_NAME Not In
			(Select FK_NAME From #TempBase)

Open		Cursor_DeleteFK
Fetch From	Cursor_DeleteFK
	Into	@FknameDFK,@TableNameDFK

While	@@Fetch_STATUS=0
	Begin
		Declare @DeleteFK NVARCHAR(MAX) = ''
		Select	@DeleteFK =
				'ALTER TABLE ' + @TableNameDFK +
				' DROP CONSTRAINT '+ @FknameDFK 
		From	#TempDestination as c
		Where	c.[table] = @TableNameDFK And
				c.FK_NAME=@FknameDFK
		
		PRINT @DeleteFK
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_DeleteFK
		Into @FknameDFK,@TableNameDFK
	End
Close		Cursor_DeleteFK
Deallocate	Cursor_DeleteFK

End /*DeleteFK*/
--======================================= 6. Index =======================================
--********** 6.1 Add Index
Begin /*AddIndex*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select		TableName = t.name,
			IndexName = ind.name,
			IndexId = ind.index_id,
			ColumnId = ic.index_column_id,
			ColumnName = col.name,
			ind.type_desc
Into		#TempBase
From		Watch.sys.indexes ind Inner Join 
			Watch.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			Watch.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			Watch.sys.tables t On ind.object_id = t.object_id 
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0 
Order By	t.name, ind.name, ind.index_id, ic.is_included_column, ic.key_ordinal;

Select		TableName = t.name,
			IndexName = ind.name,
			IndexId = ind.index_id,
			ColumnId = ic.index_column_id,
			ColumnName = col.name,
			ind.type_desc
Into		#TempDestination
From		WatchBU.sys.indexes ind Inner Join
			WatchBU.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			WatchBU.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join
			WatchBU.sys.tables t On ind.object_id = t.object_id
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0
Order By	t.name, ind.name, ind.index_id, ic.is_included_column, ic.key_ordinal;

Select	Distinct TableName,IndexName,type_desc
From	#TempBase
Except
Select	Distinct TableName,IndexName,type_desc
From	#TempDestination

Declare @tablenameAI nvarchar(50)
Declare @IndexNameAI nvarchar(50)
Declare @TypeAI nvarchar(50)

Declare @rowAI int
Set @rowAI = 0

Declare Cursor_AddIndex Cursor For
Select	Distinct TableName,IndexName,type_desc
From	#TempBase
Except
Select	Distinct TableName,IndexName,type_desc 
From	#TempDestination

Open		Cursor_AddIndex
Fetch From	Cursor_AddIndex
	Into	@tablenameAI, @IndexNameAI, @TypeAI

While	@@Fetch_STATUS=0
	Begin
		Declare @table_nameAI SYSNAME
		Select @table_nameAI='dbo.'+ @tablenameAI
		Declare @AddIndex NVARCHAR(MAX) = ''
		Select @AddIndex =
				'CREATE ' + @TypeAI + CHAR(13) + ' INDEX ' +
				@IndexNameAI+' ON '+@table_nameAI+'('+ CHAR(13) +
				STUFF((
						Select	CHAR(9) + ', [' + c.ColumnName + '] '
								+ CHAR(13)
						From	#TempBase as c
						Where	c.TableName = @tablenameAI And
								c.IndexName=@IndexNameAI
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' '
					)
					+')'
					PRINT @AddIndex
					--EXEC sys.sp_executesql @AddTable

		Fetch Next From Cursor_AddIndex
		Into	@tablenameAI, @IndexNameAI, @TypeAI
	End
Close		Cursor_AddIndex
Deallocate	Cursor_AddIndex

End /*AddIndex*/

--********** 6.2 Delete Index
Begin /*DeleteIndex*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select		TableName = t.name,
			IndexName = ind.name
Into		#TempBase
From		Watch.sys.indexes ind Inner Join
			Watch.sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			Watch.sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join
			Watch.sys.tables t ON ind.object_id = t.object_id
Where		ind.is_primary_key = 0 AND
			ind.is_unique = 0 AND
			ind.is_unique_constraint = 0 AND
			t.is_ms_shipped = 0 
Order By	t.name, ind.name, ind.index_id, ic.is_included_column, ic.key_ordinal;

Select		TableName = t.name,
			IndexName = ind.name
Into		#TempDestination
From		WatchBU.sys.indexes ind Inner Join 
			WatchBU.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join 
			WatchBU.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join
			WatchBU.sys.tables t On ind.object_id = t.object_id
Where		ind.is_primary_key = 0 And
			ind.is_unique = 0 And
			ind.is_unique_constraint = 0 And
			t.is_ms_shipped = 0
ORDER BY	t.name, ind.name, ind.index_id, ic.is_included_column, ic.key_ordinal;

Select	Distinct TableName,IndexName
From	#TempDestination
Except
Select	Distinct TableName,IndexName
From	#TempBase

Declare @tablenameDI nvarchar(50)
Declare @IndexNameDI nvarchar(50)

Declare @rowDI int
Set @rowDI = 0
Declare Cursor_DeleteIndex Cursor For
Select	Distinct TableName,IndexName
From	#TempDestination
Except
Select	Distinct TableName,IndexName
From	#TempBase

Open		Cursor_DeleteIndex
Fetch From	Cursor_DeleteIndex
	Into	@tablenameDI,@IndexNameDI

While	@@Fetch_STATUS=0
	Begin
		Declare @table_nameDI SYSNAME
		 Select @table_nameDI='dbo.'+ @tablenameDI
		 Declare @DeleteIndex NVARCHAR(MAX) = ''
		 Select @DeleteIndex =
				'DROP INDEX ' + @IndexNameDI + ' ON '+@table_nameDI
		From	#TempDestination as c
		Where	c.TableName = @tablenameDI And
				c.IndexName=@IndexNameDI
		
		PRINT @DeleteIndex
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_DeleteIndex
		Into @tablenameDI,@IndexNameDI
	END
Close		Cursor_DeleteIndex
Deallocate	Cursor_DeleteIndex

End /*DeleteIndex*/