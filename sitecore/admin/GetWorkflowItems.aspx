<%@ Page Language="C#" AutoEventWireup="true" Debug="true" %>

<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.Http" %>
<%@ Import Namespace="Sitecore.Data.Archiving" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Links" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Net.Http.Headers" %>
<%@ Import Namespace="System.Runtime.Serialization" %>
<%@ Import Namespace="System.Runtime.Serialization.Json" %>
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
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Diagnostics" %>


<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Sync VD Tables with MailChimp</title>
    <style>
        body {
            font-family: verdana, arial, sans-serif;
        }

        table.table-style-three {
            font-family: verdana, arial, sans-serif;
            font-size: 11px;
            color: #333333;
            border-width: 1px;
            border-color: #3A3A3A;
            border-collapse: collapse;
        }

            table.table-style-three th {
                border-width: 1px;
                padding: 8px;
                border-style: solid;
                border-color: #FFA6A6;
                background-color: #D56A6A;
                color: #ffffff;
            }

            table.table-style-three tr:hover td {
                cursor: pointer;
            }

            table.table-style-three tr:nth-child(even) td {
                background-color: #F7CFCF;
            }

            table.table-style-three td {
                border-width: 1px;
                padding: 8px;
                border-style: solid;
                border-color: #FFA6A6;
                background-color: #ffffff;
            }

        .positionAbsolute {
            position: absolute;
        }
    </style>

    <script language="CS" runat="server"> 
        StringBuilder sb;
        DataTable tb;
        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=GetWorkflowItems.aspx");
            }
        }

        protected void btnGetItemsInWorkflow_Click(object sender, EventArgs e)
        {
            //XTM Translation ID: {115CBA9C-D124-49D5-B9D1-314B32155AAB}
            //Translated - Awaiting approval: {C8CB5D17-7F02-4A34-B2AE-36D1DB4A7089}

            //SC7
            //Workflow: {A5BC37E7-ED96-4C1E-8590-A26E64DB55EA}
            //Workflow Draft State: {190B1C84-F1BE-47ED-AA41-F42193D9C8FC}
            lblSummary.Text = "";
            try
            {
                if (!string.IsNullOrEmpty(txtWorkflowID.Text) && !string.IsNullOrEmpty(txtWorkflowStateID.Text))
                {
                    tb = new DataTable();
                    tb.Columns.Add("Item ID");
                    tb.Columns.Add("Item Path");
                    tb.Columns.Add("Item URL");

                    var db = Factory.GetDatabase("master");
                    if (db != null)
                    {
                        var sampleWorkflow = db.WorkflowProvider.GetWorkflows();
                        var workflow = db.WorkflowProvider.GetWorkflow(txtWorkflowID.Text);

                        var listofWorkflowItems = workflow.GetItems(txtWorkflowStateID.Text);
                        if (listofWorkflowItems == null || listofWorkflowItems.Count() == 0)
                        {
                            lblSummary.Text = "No Items found";
                            lblSummary.Visible = true;
                        }
                        else
                        {
                            List<string> listofItemsInTheWorkflow = new List<string>();

                            foreach (var ii in listofWorkflowItems)
                            {
                                var currentItem = db.GetItem(ii.ItemID);

                                DataRow itemRow = tb.NewRow();
                                itemRow["Item ID"] = ii.ItemID.ToString();

                                //For Item Path == Get Item ID
                                itemRow["Item Path"] = currentItem.Paths.FullPath;

                                //convert Item Path to URL
                                string getURLWithLanguage = "";
                                if (currentItem.Fields["__Renderings"] != null && currentItem.Fields["__Renderings"].ToString() != string.Empty)
                                {
                                    string urlWithLanguage = "https://www.visitdubai.com/" + ii.Language + "/";
                                    //If Events
                                    if (currentItem.Paths.FullPath.Contains("Visiting_new"))
                                    {
                                        getURLWithLanguage = currentItem.Paths.FullPath.Replace("/sitecore/content/Home/Visiting_new/", urlWithLanguage);
                                    }
                                    else
                                    {
                                        getURLWithLanguage = currentItem.Paths.FullPath.Replace("/sitecore/content/Home/", urlWithLanguage);
                                    }
                                }

                                itemRow["Item URL"] = getURLWithLanguage.ToLower();
                                tb.Rows.Add(itemRow);
                                //lblSummary.Text += "<br>" + ii.ItemID.ToString();
                            }
                        }
                    }
                    lblCount.Text = "Total items: " + tb.Rows.Count.ToString();
                    grdLanguageReport.DataSource = tb;
                    grdLanguageReport.DataBind();
                }
            }
            catch (Exception ex)
            {
                //lblSummary.Text = ex.StackTrace.ToString();
            }
        }

    </script>

</head>
<body>
    <form id="form1" runat="server">
        <h2>Get List of Items from Workflow!</h2>
        <h4>Use this tool to get all the items in specific workflow state.</h4>
        <table>
            <tr>
                <td>Workflow ID:</td>
                <td>
                    <asp:TextBox ID="txtWorkflowID" runat="server" Width="400" Text="{115CBA9C-D124-49D5-B9D1-314B32155AAB}"></asp:TextBox></td>
            </tr>
            <tr>
                <td>Workflow State ID:</td>
                <td>
                    <asp:TextBox ID="txtWorkflowStateID" runat="server" Width="400" Text="{C8CB5D17-7F02-4A34-B2AE-36D1DB4A7089}"></asp:TextBox></td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblSummary" CssClass="positionAbsolute" Visible="false" Text="" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td>
                    <asp:Button ID="btnGetWorkflowItems" runat="server" Text="Get Items in Workflow" OnClick="btnGetItemsInWorkflow_Click" />

                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblCount" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td colspan="4">
                    <asp:GridView ID="grdLanguageReport" CssClass="table-style-three" runat="server"></asp:GridView>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
