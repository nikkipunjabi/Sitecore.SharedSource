<%@ Page Language="C#" AutoEventWireup="true" Debug="true" %>

<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="Sitecore.Collections" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="System.Data" %>

<%-- This is updated version of Language Report  --%>
<%-- In this it will fetch all the desendents of the parent item --%>
<%-- It will fetch only for items having any renderings  --%>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Language Report</title>
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
    </style>
    <script language="CS" runat="server"> 
        StringBuilder sb;
        DataTable tb;
        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=LanguageReport.aspx");
            }
        }

        protected void btnGetReport_Click(object sender, EventArgs e)
        {
            try
            {
                string path = txtPath.Text;
                Database db = Database.GetDatabase("master");
                Item parent = db.GetItem(path);
                tb = new DataTable();
                LanguageCollection languages = LanguageManager.GetLanguages(db);
                List<CultureInfo> cultureInfos = new List<CultureInfo>();
                tb.Columns.Add("Item ID");
                tb.Columns.Add("Item Path");
                foreach (Language language in languages)
                {
                    tb.Columns.Add(language.Name);
                }

                if (parent != null)
                {
                    foreach (Item childItem in parent.Axes.GetDescendants())
                    {
                        if (childItem.Fields != null && childItem.Fields["__Renderings"] != null && childItem.Fields["__Renderings"].ToString() != string.Empty)
                        {
                            DataRow itemRow = tb.NewRow();
                            itemRow[0] = childItem.ID;
                            itemRow[1] = childItem.Paths.Path;
                            foreach (var itemLanguage in childItem.Languages)
                            {
                                var item = db.GetItem(childItem.ID, itemLanguage);
                                if (item.Versions.Count > 0)
                                {
                                    if (tb.Columns[itemLanguage.Name] != null)
                                        itemRow[tb.Columns[itemLanguage.Name]] = "1";
                                }
                                else
                                {
                                    if (tb.Columns[itemLanguage.Name] != null)
                                        itemRow[tb.Columns[itemLanguage.Name]] = "0";
                                }
                            }

                            tb.Rows.Add(itemRow);
                        }
                    }
                }

                lblCount.Text = "Total items: " + tb.Rows.Count.ToString();
                grdLanguageReport.DataSource = tb;
                grdLanguageReport.DataBind();
                Session.Add("Data", tb);
            }
            catch (Exception ex)
            {
                lblCount.Text = ex.ToString();
            }
        }

        protected void btnDownload_Click(object sender, EventArgs e)
        {
            try
            {
                string attachment = "attachment; filename=LanguageReport.xls";
                Response.ClearContent();
                Response.AddHeader("content-disposition", attachment);
                Response.ContentType = "application/vnd.ms-excel";
                string tab = "";
                tb = (DataTable)Session["Data"];
                foreach (DataColumn dc in tb.Columns)
                {
                    Response.Write(tab + dc.ColumnName);
                    tab = "\t";
                }
                Response.Write("\n");
                int i;
                foreach (DataRow dr in tb.Rows)
                {
                    tab = "";
                    for (i = 0; i < tb.Columns.Count; i++)
                    {
                        Response.Write(tab + dr[i].ToString());
                        tab = "\t";
                    }
                    Response.Write("\n");
                }
                Response.End();
            }
            catch (Exception ex)
            {
                lblCount.Text = ex.ToString();
            }
        }


    </script>

</head>
<body>
    <form id="form1" runat="server">
        <h2>Language Report Tool - Visit Dubai</h2>
        <h4>Use this tool to check all available languages for given item.</h4>
        <table>
            <tr>
                <td>Provide Parent Item Path:<asp:TextBox ID="txtPath" Width="700px" runat="server"></asp:TextBox></td>
                <td>
                    <asp:Button ID="btnGetReport" runat="server" Text="Get Language Report" OnClick="btnGetReport_Click" /></td>
                <td>
                    <asp:Button ID="btnDownload" runat="server" Text="Download Report" OnClick="btnDownload_Click" /></td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblCount" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td>&nbsp;</td>
            </tr>
            <tr>
                <td colspan="3">
                    <asp:GridView ID="grdLanguageReport" CssClass="table-style-three" runat="server"></asp:GridView>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
