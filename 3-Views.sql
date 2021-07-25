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

--********** 3.2 Delete Viwe
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