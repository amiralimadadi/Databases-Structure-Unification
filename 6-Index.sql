--======================================= 6. Index =======================================
/* 
This file holds the query for copying the reference database indexes to the destination database
To execute this, you need to replace "{Base}" with your reference database name 
	and replace "{Destination}" with your destination database name
This query creates a table called "#TempBase" in tempdb, so you need access to do that.
The query contains different parts like "adding new index" and "deleting current index".
*/

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
From		{Base}.sys.indexes ind Inner Join 
			{Base}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Base}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join 
			{Base}.sys.tables t On ind.object_id = t.object_id 
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
From		{Destination}.sys.indexes ind Inner Join
			{Destination}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Destination}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join
			{Destination}.sys.tables t On ind.object_id = t.object_id
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
From		{Base}.sys.indexes ind Inner Join
			{Base}.sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join
			{Base}.sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join
			{Base}.sys.tables t ON ind.object_id = t.object_id
Where		ind.is_primary_key = 0 AND
			ind.is_unique = 0 AND
			ind.is_unique_constraint = 0 AND
			t.is_ms_shipped = 0 
Order By	t.name, ind.name, ind.index_id, ic.is_included_column, ic.key_ordinal;

Select		TableName = t.name,
			IndexName = ind.name
Into		#TempDestination
From		{Destination}.sys.indexes ind Inner Join 
			{Destination}.sys.index_columns ic On ind.object_id = ic.object_id and ind.index_id = ic.index_id Inner Join 
			{Destination}.sys.columns col On ic.object_id = col.object_id and ic.column_id = col.column_id Inner Join
			{Destination}.sys.tables t On ind.object_id = t.object_id
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