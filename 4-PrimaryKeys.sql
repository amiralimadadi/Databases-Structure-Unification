--======================================= 4. Primary Key =======================================
/* 
This file holds the query for copying the structure of primary keys reference database to the destination database
To execute this, you need to replace "{Base}" with your reference database name 
	and replace "{Destination}" with your destination database name
This query creates a table called "#TempBase" in tempdb, so you need access to do that.
The query contains 2 parts which are "adding new PK" and "deleting current PKs"
*/

--********** 4.1 Add PK
Begin /*AddPK*/

If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select c.TABLE_CATALOG,c.TABLE_NAME,c.CONSTRAINT_NAME,c.COLUMN_NAME 
Into	#TempBase
From	{Base}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as c join
		{Base}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS as t
			on c.CONSTRAINT_NAME=t.CONSTRAINT_NAME
Where	CONSTRAINT_TYPE='PRIMARY KEY'

Select	c.TABLE_CATALOG,c.TABLE_NAME,c.CONSTRAINT_NAME,c.COLUMN_NAME
Into	#TempDestination
From	{Destination}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as c join
		{Destination}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS as t
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
