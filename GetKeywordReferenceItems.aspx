﻿<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Data.Archiving" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Links" %>
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
<%@ Import Namespace="System.ComponentModel" %>

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
            Response.Redirect("http://" + HttpContext.Current.Request.Url.Host + "/sitecore/login?returnUrl=%2fsitecore%2fadmin%GetKeywordReferenceItems.aspx");
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

    public DataTable GetDataTable(string query, string strConnectionString)
    {
        String ConnString = ConfigurationManager.ConnectionStrings[strConnectionString].ConnectionString;
        SqlDataAdapter adapter = new SqlDataAdapter();
        DataTable genericTable = new DataTable();
        using (SqlConnection conn = new SqlConnection(ConnString))
        {
            adapter.SelectCommand = new SqlCommand(query, conn);
            adapter.Fill(genericTable);
        }
        return genericTable;
    }


    private void GetReferencedItems()
    {
        var strKeyword = txtKeyword.Text;

        //List<String> lstItemsId = new List<String>();

        DataTable dtItemList = new DataTable();

        dtItemList.Columns.Add("Id");
        dtItemList.Columns.Add("Name");

        var strSelectVersionedFieldsQuery = @"Select [ID], [Name] FROM [dbo].[Items]
  Where [ID] in (Select DISTINCT [ItemId] From [dbo].[VersionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND Value like '%" + strKeyword + "%')";
        var VersionedFieldsData = GetDataTable(strSelectVersionedFieldsQuery, ddDb.SelectedValue);

        if (VersionedFieldsData.Rows.Count > 0)
        {
            foreach (DataRow currentItem in VersionedFieldsData.Rows)
            {
                // lstItemsId.Add(currentItem[0].ToString());

                DataRow dr = dtItemList.NewRow();
                dr["Id"] = currentItem[0].ToString();
                dr["Name"] = currentItem[1].ToString();

                dtItemList.Rows.Add(dr);
            }

            // lstItemsId = lstItemsId.Union(VersionedFieldsData.AsEnumerable()).ToList();
        }

        var strSelectSharedFieldsQuery = @"Select [ID], [Name] FROM [dbo].[Items]
  Where [ID] in (Select DISTINCT [ItemId] From [dbo].[SharedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND Value like '%" + strKeyword + "%')";
        var SharedFieldsData = GetDataTable(strSelectSharedFieldsQuery, ddDb.SelectedValue);

        if (SharedFieldsData.Rows.Count > 0)
        {
            foreach (DataRow currentItem in SharedFieldsData.Rows)
            {
                // lstItemsId.Add(currentItem[0].ToString());

                DataRow dr = dtItemList.NewRow();
                dr["Id"] = currentItem[0].ToString();
                dr["Name"] = currentItem[1].ToString();

                dtItemList.Rows.Add(dr);
            }
            //lstItemsId = lstItemsId.Union(SharedFieldsData.AsEnumerable()).ToList();
        }

        var strSelectUnversionedFieldsQuery = @"Select [ID], [Name] FROM [dbo].[Items]
  Where [ID] in (Select DISTINCT [ItemId] From [dbo].[UnversionedFields] Where [FieldId] in (SELECT [ID] FROM [Items] Where Name NOT LIKE '\_\_%'  ESCAPE '\') AND Value like '%" + strKeyword + "%')";
        var UnversionedFieldsData = GetDataTable(strSelectUnversionedFieldsQuery, ddDb.SelectedValue);

        if (UnversionedFieldsData.Rows.Count > 0)
        {
            foreach (DataRow currentItem in UnversionedFieldsData.Rows)
            {
                //lstItemsId.Add(currentItem[0].ToString());

                DataRow dr = dtItemList.NewRow();
                dr["Id"] = currentItem[0].ToString();
                dr["Name"] = currentItem[1].ToString();

                dtItemList.Rows.Add(dr);
            }
            //lstItemsId = lstItemsId.Union(UnversionedFieldsData.AsEnumerable()).ToList();
        }

        // lblTotalCount.Text = "Total item count:" + lstItemsId.Count;
        lblTotalCount.Text = "Total item count:" + dtItemList.Rows.Count;

        if (dtItemList.Rows.Count > 0)
        {
            pnlmedias.Visible = true;

            //var dtItemsId = ToDataTable(lstItemsId);

            // lstItemsId = lstItemsId.Distinct().ToList();

            gvMediaItems.DataSource = dtItemList.DefaultView.ToTable(true, "Id", "Name");
            gvMediaItems.DataBind();

            gvMediaItems.Visible = true;
        }
    }



    protected void btnGo_Click(object sender, EventArgs e)
    {
        try
        {
            DateTime dtStartDateTime = DateTime.Now;

            lblStartTime.Text = "Start DateTime:" + dtStartDateTime.ToString("dd-MM-yyyy hh:mm:ss");
            if (!string.IsNullOrEmpty(txtKeyword.Text))
                GetReferencedItems();
            selectedDB = ddDb.SelectedValue;

            DateTime dtEndDateTime = DateTime.Now;

            lblEndTime.Text = "End DateTime:" + dtEndDateTime.ToString("dd-MM-yyyy hh:mm:ss");

            TimeSpan duration = dtEndDateTime - dtStartDateTime;

            lblDiff.Text = "Duration (minutes) :" + duration.TotalMinutes.ToString("#.##");
        }
        catch (Exception excp)
        {
            Sitecore.Diagnostics.Log.Error("Error while loading the list of unreferenced media items:" + excp.StackTrace, excp);
        }
    }
</script>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>

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
    <title>Refernced Keyword Items</title>
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
                        <label for="chkIncludeSystem" title="Keyword">Keyword</label>
                    </div>
                    <div class="col-sm-8">
                        <asp:TextBox ID="txtKeyword" Text="" Width="500" runat="server"></asp:TextBox>
                    </div>
                </div>

            </div>

            <div class="form-group">
                <asp:Button class="btn btn-default" ID="btnGo" runat="server" OnClick="btnGo_Click" Text="Get reference list" />
            </div>
            <asp:Label ID="lblMessage" runat="server"></asp:Label>
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

                    <telerik:RadGrid ID="gvMediaItems" runat="server"
                        GridLines="Both" Skin="Metro"
                        Visible="false" Width="1200px" CssClass="gridViewLayout" MasterTableView-Caption="Refernced Keyword Items List">

                        <ClientSettings>
                            <Resizing AllowColumnResize="false" AllowRowResize="false" ResizeGridOnColumnResize="false"
                                ClipCellContentOnResize="true" EnableRealTimeResize="false" AllowResizeToFit="true" ShowRowIndicatorColumn="true" />
                        </ClientSettings>
                        <ExportSettings HideStructureColumns="true" ExportOnlyData="true" FileName="UserSignups" Csv-ColumnDelimiter="comma"
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

                </div>
            </asp:Panel>

        </div>
    </form>



</body>
</html>
