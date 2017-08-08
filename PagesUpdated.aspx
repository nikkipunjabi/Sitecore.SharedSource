<%@ Page Language="C#" AutoEventWireup="true" %>

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

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <script language="CS" runat="server"> 
        StringBuilder sb;
        DataTable tb;
        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=PagesUpdated.aspx");
            }
        }
        protected void btnGetReport_Click(object sender, EventArgs e)
        {
            try
            {
                string path = txtPath.Text;
                Database db = Database.GetDatabase(txtDatabase.Text);
                Item parent = db.GetItem(path);
                string year = txtYear.Text;
                DateTime dateTimeYear = new DateTime(Convert.ToInt32(year), 1, 1);
                int globalCounter = 0;
                List<string> pages = new List<string>();
                int onlyPageCounter = 0;
                tb = new DataTable();
                LanguageCollection languages = LanguageManager.GetLanguages(db);
                List<CultureInfo> cultureInfos = new List<CultureInfo>();
                tb.Columns.Add("Item Path");
                tb.Columns.Add("Updated Date");
                tb.Columns.Add("Language");
                foreach (Item childItem in parent.Axes.GetDescendants())
                {
                    if (childItem.Fields["__Renderings"].ToString() != string.Empty)
                    {

                        onlyPageCounter = onlyPageCounter + 1;
                        foreach (var itemLanguage in childItem.Languages)
                        {
                            var item = db.GetItem(childItem.ID, itemLanguage);
                            if (item.Versions.Count > 0 && item.Statistics.Updated >= dateTimeYear)
                            {
                                globalCounter = globalCounter + 1;
                                pages.Add(item.Paths.FullPath);
                                DataRow itemRow = tb.NewRow();
                                itemRow[0] = item.Paths.FullPath;
                                itemRow[1] = item.Statistics.Updated;
                                itemRow[2] = item.Language.Name;
                                tb.Rows.Add(itemRow);
                            }
                        }
                    }
                }

                lblCount.Text = "Only page count: " + onlyPageCounter + " Total items: " + globalCounter;
                grdLanguageReport.DataSource = tb;
                grdLanguageReport.DataBind();
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
        <table>
            <tr>
                <td>Provide Parent Item Path:<asp:TextBox ID="txtPath" Width="700px" runat="server"></asp:TextBox></td>
                <td>Provide Database:<asp:TextBox ID="txtDatabase" Width="50px" runat="server"></asp:TextBox></td>
                <td>Provide Year:<asp:TextBox ID="txtYear" Width="50px" Text="2017" runat="server"></asp:TextBox></td>
                <td>
                    <asp:Button ID="btnGetReport" runat="server" Text="Get Language Report" OnClick="btnGetReport_Click" /></td>
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
