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

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Bulk Publish Tool</title>
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

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=bulkpublish-cn.aspx");
            }
        }

        private void PublishItem(Sitecore.Data.Items.Item item, bool isSubitem, string DB, string lang)
        {
            // The publishOptions determine the source and target database,
            // the publish mode and language, and the publish date
            Sitecore.Publishing.PublishOptions publishOptions =
              new Sitecore.Publishing.PublishOptions(item.Database,
                                                     Database.GetDatabase(DB),
                                                     Sitecore.Publishing.PublishMode.SingleItem,
                                                     item.Language,
                                                     System.DateTime.Now);  // Create a publisher with the publishoptions
            Sitecore.Publishing.Publisher publisher = new Sitecore.Publishing.Publisher(publishOptions);

            // Choose where to publish from
            publisher.Options.RootItem = item;

            publisher.Options.Language = Language.Parse(lang);
            // Publish children as well?
            publisher.Options.Deep = isSubitem;

            // Do the publish!
            publisher.Publish();
        }

        protected void btnPublish_Click(object sender, EventArgs e)
        {
            int count = 0;
            StringBuilder sb = new StringBuilder();
            try
            {
                sb.Append("Publishing Summary:").Append("<br/>");
                bool isSubitem = false;
                Database db = Database.GetDatabase("master");
                string[] s = txtIDs.Text.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
                if (drpIsSubItem.SelectedIndex == 1)
                {
                    isSubitem = true;
                }
                string DB = drpDB.SelectedItem.Value;
                foreach (string ii in s)
                {
                    Item i = db.GetItem(ii);
                    if (i == null || i.ID.ToString() == "{F344DBE2-BC34-49FB-8564-FD74048702D9}") { sb.Append("Item not found: " + ii).Append("<br/>"); continue; }
                    foreach (ListItem lang in chkLang.Items)
                    {
                        if (lang.Selected)
                        {
                            PublishItem(i, isSubitem, DB, lang.Value);
                            sb.Append("Item published:").Append(i.ID).Append("Language: ").Append(lang.Value).Append("<br/>");
                        }
                    }
                    count++;
                }
                sb.Append("Total published item from above given list: " + count);
            }
            catch (Exception ex)
            {
                lblError.Text = ex.ToString();
            }
            lblError.Text = sb.ToString();
        }
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Bulk Publishing Tool - Visit Dubai</h2>
        <table class="table-style-three">
            <tr>
                <%--<td style="width: 20%">Publish:
                    <asp:DropDownList ID="drpIsSubItem" runat="server">
                    <asp:ListItem Text="Without SubItem" Value="0"></asp:ListItem>
                    <asp:ListItem Text="With SubItem" Value="1"></asp:ListItem>
                    </asp:DropDownList>
                </td>--%>
                <td style="width: 90%">Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Master" Value="master"></asp:ListItem>
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="Web" Value="web"></asp:ListItem>
                    <asp:ListItem Text="HKG" Value="hkg"></asp:ListItem>
                </asp:DropDownList></td>
            </tr>
            <tr>
                <%--<td style="vertical-align: top">
                    <asp:CheckBoxList ID="chkLang" runat="server">
                        <asp:ListItem Value="zh-CN">Chinese</asp:ListItem>                        
                        <asp:ListItem Value="hk">Cantonese</asp:ListItem>             
                    </asp:CheckBoxList>
                </td>
                    --%>
                <td style="vertical-align: top">
                    <asp:TextBox ID="txtIDs" TextMode="MultiLine" Rows="50" runat="server" Height="100%" Width="98%"></asp:TextBox></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Button ID="btnPublish" runat="server" Text="Publish" OnClick="btnPublish_Click" /></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Label ID="lblError" runat="server"></asp:Label>
                </td>
            </tr>
        </table>

    </form>
</body>
</html>
