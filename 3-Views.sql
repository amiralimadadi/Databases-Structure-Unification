--======================================= 3. Viw =======================================
/* 
This file holds the query for copying the structure of views reference database to the destination database
To execute this, you need to replace "{Base}" with your reference database name 
	and replace "{Destination}" with your destination database name
This query creates a table called "#TempBase" in tempdb, so you need access to do that.
The query contains 2 parts which are "adding new Viwe" and "deleting current Views"
*/

--********** 3.1 Add Viwe
Begin /*AddViews*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select * 
Into #TempBase
From {Base}.INFORMATION_SCHEMA.VIEWS

Select * 
Into #TempDestination
From {Destination}.INFORMATION_SCHEMA.VIEWS

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
		--PRINT @AddViews
		EXEC sys.sp_executesql @AddTable
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
From	{Base}.INFORMATION_SCHEMA.VIEWS as v join
		{Base}.INFORMATION_SCHEMA.VIEW_COLUMN_USAGE as c on v.TABLE_NAME=c.VIEW_NAME

Select	c.*,v.VIEW_DEFINITION 
Into	#TempDestination
From	{Destination}.INFORMATION_SCHEMA.VIEWS as v join
		{Destination}.INFORMATION_SCHEMA.VIEW_COLUMN_USAGE as c on v.TABLE_NAME=c.VIEW_NAME
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
From {Base}.INFORMATION_SCHEMA.VIEWS

Select * 
Into #TempDestination
From {Destination}.INFORMATION_SCHEMA.VIEWS

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