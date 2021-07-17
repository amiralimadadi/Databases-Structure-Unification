--======================================= 1. Table =======================================
/* 
This file holds the query for copying the reference database structure to the destination database
To execute this, you need to replace "{Base}" with your reference database name 
	and replace "{Destination}" with your destination database name
This query creates a table called "#TempBase" in tempdb, so you need access to do that.
The query contains different parts like "adding new table" and "deleting current tables".
*/

--********** 1.1 Add Table
Begin /*AddTable*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select * 
Into	#TempBase
From	{Base}.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME Not In (Select TABLE_NAME From {Base}.INFORMATION_SCHEMA.VIEWS)

Select	* 
Into	#TempDestination
From	{Destination}.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME Not In (Select TABLE_NAME From {Destination}.INFORMATION_SCHEMA.VIEWS)

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
		EXEC sys.sp_executesql @AddTable

		Fetch Next From	Cursor_AddTable
		Into @tablename
	End
Close		Cursor_AddTable
Deallocate	Cursor_AddTable
End /*AddTable*/


--********** 1.2 Delete Table
Begin /*DeleteTable*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select	* 
Into	#TempBase
From	{Base}.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME not in (Select TABLE_NAME From {Base}.INFORMATION_SCHEMA.VIEWS)

Select	* 
Into	#TempDestination
From	{Destination}.INFORMATION_SCHEMA.COLUMNS
Where	TABLE_NAME not in (Select TABLE_NAME From {Destination}.INFORMATION_SCHEMA.VIEWS)

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
			EXEC sys.sp_executesql @Deletetable
			
			Fetch Next From	Cursor_DeleteTable
			Into @tablenameTD
	End
Close		Cursor_DeleteTable
Deallocate	Cursor_DeleteTable

End /*DeleteTable*/