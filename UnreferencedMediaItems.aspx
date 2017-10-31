<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.IO" %>
<%@ Import Namespace="Sitecore.Data.Archiving" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Links" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Web.UI.HtmlControls" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="Sitecore.Zip" %>
<%@ Import Namespace="Sitecore.ContentSearch" %>
<%@ Import Namespace="Sitecore.ContentSearch.SearchTypes" %>

<!DOCTYPE html>
<script language="C#" runat="server">   
    Database currentDB = null;
    private static String selectedDB = String.Empty;
    protected void Page_Init(object sender, EventArgs e)
    {
        //Space for custom logic
    }

    Item ContentRootItem = null;

    protected void Page_Load(object sender, EventArgs e)
    {
        //This condition allows only Administrator to access this page.
        if (!Sitecore.Context.User.IsAdministrator)
        {
            Response.Redirect("http://" + HttpContext.Current.Request.Url.Host + "/sitecore/login?returnUrl=%2fsitecore%2fadmin%2fUnreferencedMediaItems.aspx");
        }
        lblTotalCount.Attributes.Add("display", "none");

        if (!Page.IsPostBack)
        {
            foreach (string dbname in Sitecore.Configuration.Factory.GetDatabaseNames())
            {
                if (dbname.ToLower() != "core" && dbname.ToLower() != "filesystem")
                {
                    ddDb.Items.Add(new ListItem(dbname));
                }
            }
        }

    }
    public ZipWriter zipWriter;//= new ZipWriter("temp.zip");
    private void AddMediaItemToZip(MediaItem mediaItem)
    {
        //Assert.ArgumentNotNull(mediaItem, "mediaItem");
        System.IO.Stream mediaStream = mediaItem.GetMediaStream();
        if (mediaStream == null)
        {
            //Log.Warn(string.Format("Cannot find media data for item '{0}'", mediaItem.get_MediaPath()), typeof(object));
            return;
        }
        string str = string.IsNullOrEmpty(mediaItem.Extension) ? "" : ("." + mediaItem.Extension);
        this.zipWriter.AddEntry(mediaItem.MediaPath.Substring(1) + "_" + mediaItem.ID.ToString().Replace("{", "").Replace("}", "") + str, mediaStream);
    }

    public void ProcessMediaItems(Item rootMediaItem)
    {
        if (rootMediaItem.TemplateID != TemplateIDs.MediaFolder && rootMediaItem.TemplateID != TemplateIDs.MainSection)
        {
            //JobStatus expr_2E = Context.get_Job().get_Status();
            //expr_2E.set_Processed(expr_2E.get_Processed() + 1L);
            //Context.get_Job().get_Status().get_Messages().Add("Processed " + Context.get_Job().get_Status().get_Processed() + " items");
            MediaItem mediaItem = new MediaItem(rootMediaItem);
            this.AddMediaItemToZip(mediaItem);
            return;
        }
        //if (recursive)
        //{
        //    foreach (Item rootMediaItem2 in rootMediaItem.GetChildren())
        //    {
        //        this.ProcessMediaItems(rootMediaItem2, true);
        //    }
        //}
    }

    private static Item[] GetLinkedItems(Database database, Language language, Item refItem)
    {
        // getting all linked Items that refer to the “refItem” Item
        ItemLink[] links = Globals.LinkDatabase.GetReferrers(refItem);
        if (links == null)
        {
            return null;
        }

        ArrayList result = new ArrayList(links.Length);

        foreach (ItemLink link in links)
        {
            // checking the database name of the linked Item
            if (link.SourceDatabaseName == database.Name)
            {
                Item item = database.Items[link.SourceItemID, language];
                // adding the Item to an array if the Item is not null
                if (item != null)
                {
                    result.Add(item);
                }
            }
        }

        return (Item[])result.ToArray(typeof(Item));
    }

    private int GetLinkedItemsCount(Item refItem)
    {
        // getting all linked Items that refer to the “refItem” Item
        var nRefCount = Globals.LinkDatabase.GetReferrerCount(refItem);

        if (nRefCount == 0)
        {
            // lblMessage.Text += " LinkDB Zero";
            //var refItemId = refItem.ID.ToString().Replace("{", "").Replace("}", "").ToLower();
            //var refItemPath = refItem.Paths.FullPath.Replace("/sitecore/media library", "").ToLower();

            //nRefCount = GetLinkedItemsCountByPath(refItemId, refItemPath, ContentRootItem);

            var refItemId = refItem.ID.ToString().Replace("-", "").Replace("{", "").Replace("}", "").ToLower();
            var refItemIdFull = refItem.ID.ToString().Replace("{", "").Replace("}", "").ToLower();
            var refItemPath = refItem.Paths.FullPath.ToLower().Replace("/sitecore/media library", "");

            // nRefCount = GetLinkedItemsCountByQuery(refItemId, refItemIdFull, refItemPath);
            // lblMessage.Text += " SQL Query Links " + nRefCount;
        }

        return nRefCount;
    }

    private int GetLinkedItemsCountByQuery(string refItemId, string refItemIdFull, string refItemPath)
    {
        var nRefCount = 0;

        //var strSelectVersionedFieldsQuery = "Select Count([Id]) as 'Total' From [dbo].[VersionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name not like '__%') AND Value like '%" + refItemId + "%'";

        //var strSelectVersionedFieldsQuery = @"Select [Id] From [dbo].[VersionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND (Value like '%" + refItemId + "%' OR Value like '%" + refItemIdFull + "%' OR Value like '%" + refItemPath + "%')";
        var strSelectVersionedFieldsQuery = @"Select [Id] From [dbo].[VersionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND (Value like '%" + refItemId + "%' OR Value like '%" + refItemIdFull + "%')";
        var VersionedFieldsData = GetDataTable(strSelectVersionedFieldsQuery, ddDb.SelectedValue);

        if (VersionedFieldsData.Rows.Count > 0)
        {
            nRefCount = VersionedFieldsData.Rows.Count;
            return nRefCount;

            //var strVersionedFieldsCount = VersionedFieldsData.Rows[0][0].ToString();

            //var nVersionedFieldsCount  = Int32.Parse(strVersionedFieldsCount);
            //if(nVersionedFieldsCount>0)
            //{
            //    nRefCount = nVersionedFieldsCount;
            //    return nRefCount;
            //}
        }


        //var strSelectSharedFieldsQuery = "Select Count([Id]) as 'Total' From [dbo].[SharedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name not like '__%') AND Value like '%" + refItemId + "%'";

        //var strSelectSharedFieldsQuery = @"Select [Id] From [dbo].[SharedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND (Value like '%" + refItemId + "%' OR Value like '%" + refItemIdFull + "%' OR Value like '%" + refItemPath + "%')";
        var strSelectSharedFieldsQuery = @"Select [Id] From [dbo].[SharedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND (Value like '%" + refItemId + "%' OR Value like '%" + refItemIdFull + "%')";
        var SharedFieldsData = GetDataTable(strSelectSharedFieldsQuery, ddDb.SelectedValue);

        if (SharedFieldsData.Rows.Count > 0)
        {
            nRefCount = SharedFieldsData.Rows.Count;
            return nRefCount;

            //var strSharedFieldCount = SharedFieldsData.Rows[0][0].ToString();

            //var nSharedFieldCount  = Int32.Parse(strSharedFieldCount);
            //if(nSharedFieldCount>0)
            //{
            //    nRefCount = nSharedFieldCount;
            //    return nRefCount;
            //}
        }


        //var strSelectUnversionedFieldsQuery = "Select Count([Id]) as 'Total' From [dbo].[UnversionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name not like '__%') AND Value like '%" + refItemId + "%'";
        //var strSelectUnversionedFieldsQuery = @"Select [Id] From [dbo].[UnversionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND (Value like '%" + refItemId + "%' OR Value like '%" + refItemIdFull + "%' OR Value like '%" + refItemPath + "%')";
        var strSelectUnversionedFieldsQuery = @"Select [Id] From [dbo].[UnversionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND (Value like '%" + refItemId + "%' OR Value like '%" + refItemIdFull + "%')";
        var UnversionedFieldsData = GetDataTable(strSelectUnversionedFieldsQuery, ddDb.SelectedValue);

        if (UnversionedFieldsData.Rows.Count > 0)
        {
            nRefCount = UnversionedFieldsData.Rows.Count;
            return nRefCount;

            //var strUnversionedFieldCount = UnversionedFieldsData.Rows[0][0].ToString();

            //var nUnversionedFieldCount  = Int32.Parse(strUnversionedFieldCount);
            //if(nUnversionedFieldCount>0)
            //{
            //    nRefCount = nUnversionedFieldCount;
            //    return nRefCount;
            //}
        }

        return nRefCount;
    }


    private int GetLinkedItemsCountByPath(string refItemId, string refItemPath, Item rootItem)
    {
        var nRefCount = 0;

        foreach (Item currentItem in rootItem.Children)
        {

            List<string> fieldNames = new List<string>();
            currentItem.Fields.ReadAll();
            var fieldCollection = currentItem.Fields.Where(x => !x.Name.StartsWith("__")).Select(x => x.Name).ToList();

            foreach (var fieldName in fieldCollection)
            {
                if (currentItem[fieldName].ToLower().Contains(refItemId) || currentItem[fieldName].ToLower().Contains(refItemPath))
                {
                    nRefCount++;
                    break;
                }
            }

            if (nRefCount > 0)
                break;

            if (currentItem.Children.Count > 0)
            {
                nRefCount = GetLinkedItemsCountByPath(refItemId, refItemPath, currentItem);
            }
        }

        return nRefCount;
    }

    public DataTable GetDataTable(string query, string strConnectionString)
    {
        DataTable genericTable = new DataTable();
        try
        {
            String ConnString = ConfigurationManager.ConnectionStrings[strConnectionString].ConnectionString + ";Connection Timeout=2500;";
            SqlDataAdapter adapter = new SqlDataAdapter();

            using (SqlConnection conn = new SqlConnection(ConnString))
            {
                adapter.SelectCommand = new SqlCommand(query, conn);
                adapter.SelectCommand.CommandTimeout = 300;
                adapter.Fill(genericTable);
            }

        }
        catch (Exception ex)
        {

        }
        return genericTable;
    }


    private void GetUnusedMediaList(Item mediaRootItem, int nRootLevel)
    {
        foreach (Item MedItm in mediaRootItem.Children)
        {
            if (MedItm != null && MedItm.TemplateID.ToString() != "{FE5DD826-48C6-436D-B87A-7C4210C7413B}")
            {

                //if (MedItm.Statistics.Updated.Year <= 2015)
                //{

                //}

                bool valid = true;
                //if (chkIncludeSystem.Checked)
                //{

                //}
                //else
                //{
                //    if (MedItm.Paths.Path.ToLower().Contains("/sitecore/media library/system/"))
                //        valid = false;
                //}

                TotalMediaCount++;

                if (TotalMediaCount > nMaxCount)
                {
                    break;
                }
                if (nMinCount <= TotalMediaCount)
                {
                    ProcessedMediaCount++;
                    if (valid && GetLinkedItemsCount(MedItm) == 0)
                    {
                        UnusedMedia.Add(MedItm);
                        count++;

                        //lblMessage.Text += " Searching in index";
                        //// Search in index, if media item is referenced in content
                        //var isReferencedinContent = SearchMediaInIndex(MedItm);
                        //lblMessage.Text += " " + isReferencedinContent.ToString() + "<br />";

                    }
                    //else
                    //{
                    //    lblMessage.Text += string.Format("Media item with ID {0} is referenced!<br />", MedItm.ID.ToString());
                    //}
                }

                //if (TotalMediaCount > 15)
                //    break;
            }

            if (MedItm != null)
            {
                if (nRootLevel < nDepthLevel)
                {
                    if (MedItm.Children.Count > 0)
                    {
                        GetUnusedMediaList(MedItm, nRootLevel++);
                    }
                }
            }
        }

    }

    List<Item> UnusedMedia = new List<Item>();
    int count = 0;
    int TotalMediaCount = 0;
    int ProcessedMediaCount = 0;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="MedItm"></param>
    /// <returns></returns>
    public bool SearchMediaInIndex(MediaItem MedItm)
    {
        using (var searchIndex = ContentSearchManager.GetIndex("sitecore_master_index").CreateSearchContext())
        {
            //Perform the search on index
            if (searchIndex != null)
            {
                var strMediaItemId = MedItm.ID.ToShortID().ToString().ToLower();
                lblMessage.Text += " Media ID " + strMediaItemId;
                var searchResult = searchIndex.GetQueryable<SearchResultItem>().Where(item => item.Content.Contains(strMediaItemId)).ToList();
                if (!searchResult.Any())
                {
                    lblMessage.Text += " No reference found!";
                    return false;
                }
            }
        }
        return true;
    }

    /// <summary>
    /// Loads all unreferenced Media except the Media Folder.
    /// </summary>
    public void LoadUnreferencedItems()
    {
        currentDB = Sitecore.Data.Database.GetDatabase(ddDb.SelectedValue);
        //if (dddb.selectedvalue == "master")
        //{
        //    sitecore.context.setactivesite("shell");
        //    currentdb = sitecore.context.contentdatabase;
        //}
        string mediaItemrootpath = "/sitecore/media library/";
        if (!string.IsNullOrEmpty(txtmediarootpath.Text))
        {
            mediaItemrootpath = txtmediarootpath.Text;
        }
        var strContentRootPath = "/sitecore/content";

        ContentRootItem = currentDB.GetItem(strContentRootPath);
        //Get the media library item
        Item MediaLibrary = currentDB.GetItem(mediaItemrootpath);
        if (MediaLibrary != null)
        {
            lblMessage.Text = string.Empty;


            GetUnusedMediaList(MediaLibrary, 1);
            sbMessage.Append("<table>");
            sbMessage.Append("<tr><th>Media Path</th><th>Date Created</th><th>Date Updated</th></tr>");
            foreach (Item mediaItem in UnusedMedia.OrderBy(i => i.Statistics.Created))
            {
                sbMessage.AppendFormat("<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>", mediaItem.Paths.Path, mediaItem.Statistics.Created.Date.ToString("dd/MM/yyyy"), mediaItem.Statistics.Updated.Date.ToString("dd/MM/yyyy"));
            }
            sbMessage.Append("</table>");

            lblMessage.Text += sbMessage.ToString();
            //foreach (Item MedItm in MediaLibrary.Axes.GetDescendants())
            //{
            //    if (MedItm != null && MedItm.TemplateID.ToString() != "{FE5DD826-48C6-436D-B87A-7C4210C7413B}")
            //    {
            //        bool valid = true;
            //        //if (chkIncludeSystem.Checked)
            //        //{

            //        //}
            //        //else
            //        //{
            //        //    if (MedItm.Paths.Path.ToLower().Contains("/sitecore/media library/system/"))
            //        //        valid = false;
            //        //}
            //        if (valid && GetLinkedItemsCount(MedItm) == 0)
            //        {
            //            UnusedMedia.Add(MedItm);
            //            count++;
            //        }
            //        TotalMediaCount++;
            //        if (TotalMediaCount > 15)
            //            break;
            //    }
            //}
            //Count of total media items vs unreferenced media items

            if (TotalMediaCount > nMaxCount)
                TotalMediaCount = TotalMediaCount - 1;

            lblTotalCount.Text = "Total Media item count:" + (TotalMediaCount);
            lblTotalCount.Text += "<br/> Processed media item Count:" + ProcessedMediaCount;
            lblTotalCount.Text += "<br/> Unreferenced media item Count:" + count;
            lblTotalCount.Text += "<br/>";


            if (UnusedMedia.Count > 0)
            {
                string datafolderPath = Settings.DataFolder + "/UnusedMediaExport";
                string strFileName = DateTime.Now.ToString("yyyyMMddTHHmmss") + ".zip";
                FileUtil.CreateFolder(FileUtil.MapPath(datafolderPath));
                string fullFilePath = FileUtil.MapPath(FileUtil.MakePath(datafolderPath, strFileName, '/'));
                hdfFilePath.Value = fullFilePath;

                zipWriter = new ZipWriter(fullFilePath);

                pnlmedias.Visible = true;

                DataTable dtMediaList = new DataTable();
                dtMediaList.Columns.Add("Id");
                dtMediaList.Columns.Add("Path");
                dtMediaList.Columns.Add("Name");

                foreach (var unusedMediaItem in UnusedMedia)
                {
                    DataRow dr = dtMediaList.NewRow();
                    dr["Id"] = unusedMediaItem.ID.ToString();
                    dr["Path"] = unusedMediaItem.Paths.FullPath.ToString();
                    dr["Name"] = unusedMediaItem.Name.ToString();

                    dtMediaList.Rows.Add(dr);

                    ProcessMediaItems(unusedMediaItem);
                }


                gvMediaItems.DataSource = dtMediaList;
                gvMediaItems.DataBind();

                gvMediaItems.Visible = true;


                btnDownloadZip.Visible = true;

                zipWriter.Dispose();



                //rptUnusedItems.DataSource = UnusedMedia;
                //rptUnusedItems.DataBind();
            }
            if (rptUnusedItems.Items.Count > 0)
            {
                btnDelete.Enabled = true;
                btnPermDelete.Enabled = true;
            }
        }
        else
        {
            pnlmedias.Visible = false;
            lblMessage.Text = "Specified path is not found";
            Sitecore.Diagnostics.Log.Info("Media Library is null", this);
        }


    }

    int nDepthLevel = 1;

    int nMinCount = 1;

    int nMaxCount = 50;

    protected void btnDownloadZip_Click(object sender, EventArgs e)
    {
        string strFilePath = hdfFilePath.Value;
        if (!string.IsNullOrEmpty(strFilePath))
        {
            System.IO.FileInfo Dfile = new System.IO.FileInfo(strFilePath);

            Response.Clear();
            Response.AddHeader("Content-Disposition", "attachment; filename=" + Dfile.Name);
            Response.AddHeader("Content-Length", Dfile.Length.ToString());
            Response.ContentType = "application/octet-stream";
            Response.WriteFile(Dfile.FullName);
            Response.End();
        }
    }
    StringBuilder sbMessage;
    protected void btnGo_Click(object sender, EventArgs e)
    {
        try
        {
            DateTime dtStartDateTime = DateTime.Now;
            sbMessage = new StringBuilder();

            lblStartTime.Text = "Start DateTime:" + dtStartDateTime.ToString("dd-MM-yyyy hh:mm:ss");

            var strDepthLevel = txtDepthLevel.Text;

            if (!string.IsNullOrEmpty(strDepthLevel))
            {
                int tempLevel = 0;
                Int32.TryParse(strDepthLevel, out tempLevel);
                if (tempLevel > 0)
                {
                    nDepthLevel = tempLevel;
                }
            }

            var strMinCount = txtMinCount.Text;

            if (!string.IsNullOrEmpty(strMinCount))
            {
                int tempLevel = 0;
                Int32.TryParse(strMinCount, out tempLevel);
                if (tempLevel > 0)
                {
                    nMinCount = tempLevel;
                }
            }

            var strMaxCount = txtMaxCount.Text;

            if (!string.IsNullOrEmpty(strMaxCount))
            {
                int tempLevel = 0;
                Int32.TryParse(strMaxCount, out tempLevel);
                if (tempLevel > 0)
                {
                    nMaxCount = tempLevel;
                }
            }

            LoadUnreferencedItems();
            selectedDB = ddDb.SelectedValue;

            DateTime dtEndDateTime = DateTime.Now;

            lblEndTime.Text = "End DateTime:" + dtEndDateTime.ToString("dd-MM-yyyy hh:mm:ss");

            TimeSpan duration = dtEndDateTime - dtStartDateTime;

            lblDiff.Text = "Duration (minutes) :" + duration.TotalMinutes.ToString("0.##");
        }
        catch (Exception excp)
        {
            lblEndTime.Text += "Exeption - " + excp.StackTrace;
            lblDiff.Text += "Exeption Message - " + excp.Message;
            lblMessage.Text += "Counter - " + count.ToString();
            Sitecore.Diagnostics.Log.Error("Error while loading the list of unreferenced media items:" + excp.StackTrace, excp);
        }
    }

    /// <summary>
    /// Moves media item to Recycle Bin.
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void btnDelete_Click(object sender, EventArgs e)
    {
        try
        {
            currentDB = Sitecore.Context.Database;
            if (!String.IsNullOrEmpty(selectedDB) && selectedDB == "master")
            {
                Sitecore.Context.SetActiveSite("shell");
                currentDB = Sitecore.Context.ContentDatabase;
            }
            foreach (RepeaterItem rptItem in rptUnusedItems.Items)
            {
                CheckBox chkItem = (CheckBox)rptItem.FindControl("chkItem");
                if (chkItem.Checked)
                {
                    Label lblItemID = (Label)rptItem.FindControl("lblItemID");
                    if (!String.IsNullOrEmpty(lblItemID.Text))
                    {
                        Item itm = currentDB.GetItem(lblItemID.Text);
                        if (itm != null)
                        {
                            itm.Recycle();
                        }
                    }
                }
            }
            LoadUnreferencedItems();
            lblMessage.Text = "Selected item(s) has been moved to Recycle bin. You can restore the item from Recycle bin.";
        }
        catch (Exception excp)
        {
            lblMessage.Text = excp.ToString();
        }

    }

    /// <summary>
    /// Deletes the media item permanently
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void btnPermDelete_Click(object sender, EventArgs e)
    {
        try
        {
            currentDB = Sitecore.Context.Database;
            if (!String.IsNullOrEmpty(selectedDB) && selectedDB == "master")
            {
                Sitecore.Context.SetActiveSite("shell");
                currentDB = Sitecore.Context.ContentDatabase;
            }
            foreach (RepeaterItem rptItem in rptUnusedItems.Items)
            {
                CheckBox chkItem = (CheckBox)rptItem.FindControl("chkItem");
                if (chkItem.Checked)
                {
                    Label lblItemID = (Label)rptItem.FindControl("lblItemID");
                    if (!String.IsNullOrEmpty(lblItemID.Text))
                    {
                        Item itm = currentDB.GetItem(lblItemID.Text);
                        if (itm != null)
                        {
                            itm.Delete();
                        }
                    }
                }
            }
            LoadUnreferencedItems();
            lblMessage.Text = "Selected item(s) has been permanently deleted.";
        }
        catch (Exception excp)
        {
            lblMessage.Text = excp.ToString();
        }

    }

    /// <summary>
    /// Deletes all the items from Recycle Bin
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void btnEmptyRecycleBin_Click(object sender, EventArgs e)
    {
        string archiveName = "recyclebin";
        var database = Sitecore.Data.Database.GetDatabase(ddDb.SelectedValue); // Get content database

        Archive archive = Sitecore.Data.Archiving.ArchiveManager.GetArchive(archiveName, database);
        archive.RemoveEntries();
    }

    protected void rptUnusedItems_ItemDataBound(object sender, RepeaterItemEventArgs e)
    {
        //if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
        //{
        //    HtmlAnchor lnkScreenShot = e.Item.FindControl("lnkScreenShot") as HtmlAnchor;

        //    if (((Item)e.Item.DataItem).Paths.IsMediaItem)
        //    {
        //        MediaItem mditm = new MediaItem((Item)e.Item.DataItem);
        //        string mediaUrl = Sitecore.Resources.Media.MediaManager.GetMediaUrl(mditm);
        //        if (mediaUrl.Contains("/sitecore/shell"))
        //        {
        //            mediaUrl = mediaUrl.Replace("/sitecore/shell", "");
        //        }
        //        //To have a preview of images.
        //        if (mditm.Extension.ToLower().Contains("jpg") || mditm.Extension.ToLower().Contains("jpeg") || mditm.Extension.ToLower().Contains("png") || mditm.Extension.ToLower().Contains("gif"))
        //        {
        //            if (lnkScreenShot != null)
        //            {
        //                lnkScreenShot.Attributes.Add("rel", Sitecore.Resources.Media.MediaManager.GetMediaUrl(mditm));
        //                lnkScreenShot.HRef = Sitecore.Resources.Media.MediaManager.GetMediaUrl(mditm);
        //                lnkScreenShot.Target = "_balnk";
        //            }
        //        }
        //    }



        //}
    }
</script>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <script type="text/javascript">
        function MediaItemDeleteConfirmation() {
            return confirm("Are you sure you want to move selected Items to recylce bin?");
        }
        function EmptyRecycleBinConfirmation() {
            return confirm("Are you sure you want to delete all items permanently from recycle bin?");
        }

        function MediaItemPermDeleteConfirmation() {
            return confirm("Are you sure you want to delete selected Items permanently?");
        }

    </script>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>

    <script type="text/javascript">
        $(function () {
            $("#unusedItems [id*=chkHeader]").click(function () {
                if ($("#unusedItems [id*=chkHeader]").is(":checked")) {
                    $("#unusedItems [id*=chkItem]").attr("checked", "checked");
                    $("#unusedItems [id*=chkItem]").prop("checked", true);
                } else {
                    $("#unusedItems [id*=chkItem]").removeAttr("checked");
                }
            });
            $("#unusedItems [id*=chkItem]").click(function () {
                if ($("#unusedItems [id*=chkItem]").length == $("#unusedItems [id*=chkItem]:checked").length) {
                    $("#unusedItems [id*=chkHeader]").attr("checked", "checked");
                    $("#unusedItems [id*=chkHeader]").prop("checked", true);
                } else {
                    $("#unusedItems [id*=chkHeader]").removeAttr("checked");
                }
            });
        });
    </script>
    <script type="text/javascript">
        this.screenshotPreview = function () {
            /* CONFIG */
            xOffset = 10;
            yOffset = 30;

            // these 2 variable determine popup's distance from the cursor
            // you might want to adjust to get the right result

            /* END CONFIG */
            $("a.screenshot").hover(function (e) {
                this.t = this.title;
                this.title = "";
                var c = (this.t != "") ? "<br/>" + this.t : "";
                $("body").append("<p id='screenshot'><img src='" + this.rel + "' alt='url preview' />" + c + "</p>");
                $("#screenshot")
                    .css("top", (e.pageY - xOffset) + "px")
                    .css("left", (e.pageX + yOffset) + "px")
                    .fadeIn("fast");
            },
            function () {
                this.title = this.t;
                $("#screenshot").remove();
            });
            $("a.screenshot").mousemove(function (e) {
                $("#screenshot")
                    .css("top", (e.pageY - xOffset) + "px")
                    .css("left", (e.pageX + yOffset) + "px");
            });
        };


        // starting the script on page load
        $(document).ready(function () {
            screenshotPreview();
        });
    </script>

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
    <script src="https://code.jquery.com/jquery-1.11.3.min.js"></script>
    <script src="http://cdn.datatables.net/1.10.10/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/colreorder/1.3.0/js/dataTables.colReorder.min.js"></script>
    <script src="https://cdn.datatables.net/fixedcolumns/3.2.0/js/dataTables.fixedColumns.min.js"></script>


    <link href='https://fonts.googleapis.com/css?family=Roboto:400,900' rel='stylesheet' type='text/css' />
    <link rel="stylesheet" href="http://cdn.datatables.net/1.10.10/css/jquery.dataTables.min.css" type="text/css" />

    <style>
        #meditmTbl {
            width: 100%;
        }

        thead .itmnm {
            max-width: 35%;
        }

        thead .itmpath {
            max-width: 35%;
        }

        thead .itmid {
            max-width: 20%;
        }
    </style>


    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap-theme.min.css">

    <!-- Latest compiled and minified JavaScript -->
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
    <title>Unreferenced Media Items</title>
    <style>
        .jumbotron, .footer {
            display: none;
        }

            .jumbotron .h1, .jumbotron h1 {
                font-size: 48px;
            }

            .jumbotron p {
                font-size: 16px;
            }


        .aspNetDisabled {
            -webkit-appearance: button;
            cursor: pointer;
            text-shadow: 0 1px 0 #fff;
            background-image: -webkit-linear-gradient(top,#fff 0,#e0e0e0 100%);
            background-image: -o-linear-gradient(top,#fff 0,#e0e0e0 100%);
            background-image: -webkit-gradient(linear,left top,left bottom,from(#fff),to(#e0e0e0));
            background-image: linear-gradient(to bottom,#fff 0,#e0e0e0 100%);
            filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffffff', endColorstr='#ffe0e0e0', GradientType=0);
            filter: progid:DXImageTransform.Microsoft.gradient(enabled=false);
            background-repeat: repeat-x;
            border-color: #dbdbdb;
            border-color: #ccc;
            display: inline-block;
            padding: 6px 12px;
            margin-bottom: 0;
            font-size: 14px;
            font-weight: 400;
            line-height: 1.42857143;
            text-align: center;
            white-space: nowrap;
            vertical-align: middle;
            -ms-touch-action: manipulation;
            touch-action: manipulation;
            -webkit-user-select: none;
            box-shadow: inset 0 1px 0 rgba(255,255,255,.15),0 1px 1px rgba(0,0,0,.075);
            background-image: linear-gradient(to bottom,#fff 0,#e0e0e0 100%);
            text-shadow: 0 1px 0 #fff;
            -webkit-appearance: button;
            color: #333;
            border-color: #adadad;
        }

        input[type=checkbox], input[type=radio] {
            height: 16px;
            width: 16px;
        }

        th, td {
            border: 1px solid #000;
        }
    </style>
    <style>
        img {
            border: none;
            max-width: 400px;
            width: 100%;
            height: auto;
        }
        /*  */

        #screenshot {
            position: absolute;
            border: 1px solid #ccc;
            /*background: #333;*/
            padding: 5px;
            display: none;
            color: #fff;
        }

        /*  */
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <div class="jumbotron">
                <h1>Remove Unreferenced Media Items from Sitecore</h1>
                <p>This tool is used to listout and/or remove the unreferenced media items from the CMS.</p>
                <p>
                    <b>This tool will list out the media items which are not linked to any item in CMS. It might be possible that the media listed by this tool is used in Code/CSS(Backend Code). Therefore we suggest you to ensure and confirm before deleting any media item.<br />
                        <br />

                        <p>
                            Options:<br />
                            Database: Select the database from which you want to remove the media<br />
                            Include media of System Folder: - it will include the media items of system folder. System folder is used by sitecore.<br />
                            Give appropriate path of the media root folder. If blank, it will take sitecore/media library path.<br />
                            Click on the 'Go' button to list all the unused media items.<br />
                            Select the items you want to remove by checking the checkbox<br />
                            Once 'Move to Recycle bin' button is clicked all the selected items will be moved to <b>Recycle Bin</b>. You can restore the mistakenly deleted item from Recyle bin.<br />
                            <b>If you click on 'Delete button', the selected items will be deleted permanently and can not be recovered.</b>
                        </p>
            </div>
            <div class="form-group">
                <div class="row">
                    <div class="col-sm-4">
                        <label for="ddDb" title="Please select database">Please select database:</label>
                    </div>
                    <div class="col-sm-8">
                        <asp:DropDownList ID="ddDb" runat="server" AutoPostBack="true"></asp:DropDownList>
                    </div>
                </div>

                <div class="row">
                    <div class="col-sm-4">
                        <label for="txtmediarootpath" title="Media Item root path">Media Item root path:</label>
                    </div>
                    <div class="col-sm-8">
                        <%--<asp:TextBox ID="txtmediarootpath" Text="/sitecore/media library/DFF/2017/Articles/Top-20-hidden-gems" Width="500" runat="server"></asp:TextBox>--%>
                        <asp:TextBox ID="txtmediarootpath" Text="/sitecore/media library" Width="500" runat="server"></asp:TextBox>
                    </div>
                </div>

                <div class="row">
                    <div class="col-sm-4">
                        <label for="txtDepthLevel" title="Depth Level">Depth Level</label>
                    </div>
                    <div class="col-sm-8">
                        <asp:TextBox ID="txtDepthLevel" Text="1" Width="50" runat="server"></asp:TextBox>
                    </div>
                </div>

                <div class="row">
                    <div class="col-sm-4">
                        <label for="txtMinCount" title="Min Count">Min Count</label>
                    </div>
                    <div class="col-sm-8">
                        <asp:TextBox ID="txtMinCount" Text="1" Width="50" runat="server"></asp:TextBox>
                    </div>
                </div>

                <div class="row">
                    <div class="col-sm-4">
                        <label for="txtMaxCount" title="Max Count">Max Count</label>
                    </div>
                    <div class="col-sm-8">
                        <asp:TextBox ID="txtMaxCount" Text="50" Width="50" runat="server"></asp:TextBox>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <asp:Button class="btn btn-default" ID="btnGo" runat="server" OnClick="btnGo_Click" Text="Get Unused List" />
                <asp:Button class="btn btn-default" ID="btnDelete" runat="server" OnClientClick="if (!MediaItemDeleteConfirmation()) return false;" OnClick="btnDelete_Click" Text="Move to Recycle bin" Enabled="true" Visible="true" />
                <asp:Button class="btn btn-default" ID="btnPermDelete" runat="server" OnClientClick="if (!MediaItemPermDeleteConfirmation()) return false;" OnClick="btnPermDelete_Click" Text="Delete" Enabled="false" Visible="false" />

                <%--  <asp:Button class="btn btn-default" ID="btnEmptyRecycleBin" OnClientClick="if (!EmptyRecycleBinConfirmation()) return false;" runat="server" OnClick="btnEmptyRecycleBin_Click" Text="Empty Recycle bin" />--%>
            </div>
            <div class="row">
                <div class="col-lg-12">
                    <asp:Label ID="lblMessage" runat="server"></asp:Label>
                </div>
            </div>
            <br />
            <asp:Panel ID="pnlmedias" runat="server">
                <div class="form-group">
                    <asp:Label ID="lblTotalCount" runat="server"></asp:Label>
                    <br />
                    <asp:Label ID="lblStartTime" runat="server"></asp:Label>
                    <br />
                    <asp:Label ID="lblEndTime" runat="server"></asp:Label>

                    <br />
                    <asp:Label ID="lblDiff" runat="server"></asp:Label>
                </div>
                <asp:ScriptManager ID="MainScriptManager" runat="server" />
                <div class="form-group" id="unusedItems">
                    <asp:Button runat="server" ID="btnDownloadZip" Text="Download unused media as zip" Visible="false" OnClick="btnDownloadZip_Click" CssClass="dt-body-right" />
                    <asp:HiddenField runat="server" ID="hdfFilePath" />
                    <telerik:RadGrid ID="gvMediaItems" runat="server"
                        GridLines="Both" Skin="Metro"
                        Visible="false" Width="1200px" CssClass="gridViewLayout" MasterTableView-Caption="Unused Media Items List">

                        <ClientSettings>
                            <Resizing AllowColumnResize="false" AllowRowResize="false" ResizeGridOnColumnResize="false"
                                ClipCellContentOnResize="true" EnableRealTimeResize="false" AllowResizeToFit="true" ShowRowIndicatorColumn="true" />
                        </ClientSettings>
                        <ExportSettings HideStructureColumns="true" ExportOnlyData="true" FileName="UnusedMediaList" Csv-ColumnDelimiter="comma"
                            Csv-RowDelimiter="NewLine"
                            Csv-EncloseDataWithQuotes="False">
                            <Pdf PageTitle="User Signup Details for Dubai Calendar" PaperSize="A4" DefaultFontFamily="Arial Unicode MS" />
                        </ExportSettings>
                        <MasterTableView Width="100%" CommandItemDisplay="Top">
                            <CommandItemSettings ShowExportToWordButton="false" ShowExportToCsvButton="true" ShowExportToExcelButton="true" ShowExportToPdfButton="true" ShowAddNewRecordButton="false" ShowRefreshButton="false" />
                        </MasterTableView>
                        <ClientSettings AllowDragToGroup="false" AllowColumnsReorder="false" ReorderColumnsOnClient="True">
                            <Scrolling AllowScroll="false" UseStaticHeaders="false" />
                        </ClientSettings>
                    </telerik:RadGrid>


                    <asp:Repeater ID="rptUnusedItems" runat="server" OnItemDataBound="rptUnusedItems_ItemDataBound">
                        <HeaderTemplate>

                            <div class="table-responsive">
                                <table class="table" width="100%" id="meditmTbl">
                                    <thead>
                                        <tr>
                                            <td>
                                                <asp:CheckBox ID="chkHeader" runat="server" ClientIDMode="Static" /></td>
                                            <td class="itmnm">Item Name</td>
                                            <td class="itmpath">Path</td>
                                            <td class="itmid">ID</td>
                                        </tr>
                                    </thead>
                        </HeaderTemplate>
                        <ItemTemplate>

                            <tr>
                                <td class="itmnm">
                                    <asp:CheckBox ID="chkItem" runat="server" ClientIDMode="Static" /></td>
                                <td class="itmpath">
                                    <%--<a href="#" class="screenshot" id="lnkScreenShot" runat="server">--%>
                                    <%# ((Sitecore.Data.Items.Item)Container.DataItem).Name%>
                                    <%--</a>--%>
                                </td>
                                <td><%# ((Sitecore.Data.Items.Item)Container.DataItem).Paths.Path%></td>
                                <td>
                                    <asp:Label ID="lblItemID" runat="server" Text="<%# ((Sitecore.Data.Items.Item)Container.DataItem).ID%>"></asp:Label></td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate>
                            </table>
                        </div>
                       
                        </FooterTemplate>
                    </asp:Repeater>
                </div>
            </asp:Panel>

        </div>
    </form>

    <script type="text/javascript">
        $(document).ready(function () {
            var table =
        $('#meditmTbl').DataTable({
            "pagingType": "full_numbers",
            "order": [[2, "asc"]],
            "aoColumnDefs": [
    { "bSortable": false, "aTargets": [0] }
            ],
            "colReorder": {
                fixedColumnsLeft: 1,
                fixedColumnsRight: 0
            }
        });
        });
    </script>
    <footer class="footer">
        <div class="container">
            <p class="text-muted">
                Author Information:<br />
                Urvesh Vekariya<br />
                Email:<a href="mailto:urvesh.vekariya@gmail.com" target="_top"> urvesh.vekariya@gmail.com </a>
                <br />

            </p>
        </div>
    </footer>

</body>
</html>
