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
    <title>Get Field Value</title>
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

        .red-bg {
            background-color: #F7CFCF !important;
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
                Response.Redirect("login.aspx?returnUrl=getfieldvalue.aspx");
            }
        }


        protected void btnPublish_Click(object sender, EventArgs e)
        {
            int count = 0;
            var listItemIds = new List<string>();
            var tb = new System.Data.DataTable();
            tb.Columns.Add("ID");
            StringBuilder sb = new StringBuilder();
            try
            {
                // sb.Append("Summary:").Append("<br />");
                //tb.Columns.Add("Summary:");
                string strDB = drpDB.SelectedItem.Value;

                Database db = null;

                try
                {
                    db = Database.GetDatabase(strDB);

                }
                catch (Exception ex)
                {
                    sb.Append(ex.Message).Append("<br/>");
                }

                if (db != null)
                {
                    string[] strArray = txtIDs.Text.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
                    sb.Append("<table>");
                    var row = 0;

                    foreach (string valueSet in strArray)
                    {

                        System.Data.DataRow itemRow = tb.NewRow();

                        Item i = db.GetItem(valueSet);

                        if (i == null || i.ID.ToString() == "{F344DBE2-BC34-49FB-8564-FD74048702D9}")
                        {
                            sb.Append("<tr><td>");
                            sb.Append("Item not found:");
                            sb.Append("</td><tr>");
                            continue;
                        }
                        var strLanguage = "en";
                        strLanguage = txtLanguage.Text;

                        var language = i.Languages.FirstOrDefault(l => l.Name == txtLanguage.Text);
                        if (language != null)
                        {
                            var languageSpecificItem = db.GetItem(i.ID, language);
                            if (languageSpecificItem != null && languageSpecificItem.Versions.Count > 0)
                            {
                                string[] arrFieldNames = txtFieldName.Text.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);

                                foreach (string strFieldName in arrFieldNames)
                                {
                                    var field = i.Fields[strFieldName];
                                    if (field != null)
                                    {
                                        if (row == 0)
                                        {
                                            if (!tb.Columns.Contains(field.Name))
                                            {
                                                tb.Columns.Add(field.Name);
                                            }
                                            else
                                            {
                                                tb.Columns.Add(field.Name + "_" + field.ID);
                                            }
                                        }

                                        itemRow[strFieldName] = i.Fields[strFieldName].GetValue(true);
                                    }
                                }
                            }
                            itemRow["ID"] = i.ID.ToString();
                            tb.Rows.Add(itemRow);
                            row++;
                        }
                    }
                    sb.Append("</table>");

                    grdLanguageReport.DataSource = tb;
                    grdLanguageReport.DataBind();
                }
            }

            catch (Exception ex)
            {
                lblError.Text = ex.Message;
            }

            lblError.Text = sb.ToString();

            //lblError.Text = sb.ToString();
        }
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Get FIeld Value - Visit Dubai</h2>
        <table class="table-style-three" style="width: 70%">
            <tr>
                <%-- <td style="width: 22%">Update Datasource:<asp:DropDownList ID="drpIsSubItem" runat="server">
                    <asp:ListItem Text="Without SubItem" Value="0"></asp:ListItem>
                    <asp:ListItem Text="With SubItem" Value="1"></asp:ListItem>
                </asp:DropDownList></td>--%>
                <td>Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Master" Value="master"></asp:ListItem>
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="Web" Value="web"></asp:ListItem>
                    <asp:ListItem Text="HKG" Value="hkg"></asp:ListItem>
                </asp:DropDownList></td>
                <td>Field Name:
                    <asp:TextBox ID="txtFieldName" runat="server"></asp:TextBox>
                </td>
                <td>Language:
                    <asp:TextBox ID="txtLanguage" runat="server"></asp:TextBox>
                </td>
            </tr>

            <tr>
                <%--<td style="vertical-align: top">
                    <asp:CheckBoxList ID="chkLang" runat="server" Visible="false">
                        <asp:ListItem Value="en">English</asp:ListItem>
                        <asp:ListItem Value="ar">Arabic</asp:ListItem>
                        <asp:ListItem Value="az">Azeri</asp:ListItem>
                        <asp:ListItem Value="cs">Czech</asp:ListItem>
                        <asp:ListItem Value="de">German</asp:ListItem>
                        <asp:ListItem Value="es">Spanish</asp:ListItem>
                        <asp:ListItem Value="fr">French</asp:ListItem>
                        <asp:ListItem Value="id">Indonesian</asp:ListItem>
                        <asp:ListItem Value="it">Italian</asp:ListItem>
                        <asp:ListItem Value="ja">Japanese</asp:ListItem>
                        <asp:ListItem Value="ko">Korean</asp:ListItem>
                        <asp:ListItem Value="nl">Dutch</asp:ListItem>
                        <asp:ListItem Value="pl">Polish</asp:ListItem>
                        <asp:ListItem Value="pt">Portuguese</asp:ListItem>
                        <asp:ListItem Value="ru">Russian</asp:ListItem>
                        <asp:ListItem Value="sv">Swedish</asp:ListItem>
                        <asp:ListItem Value="uk">Ukrainian</asp:ListItem>
                        <asp:ListItem Value="hk">Cantonese</asp:ListItem>
                    </asp:CheckBoxList>
                </td>--%>
                <td style="vertical-align: top" colspan="2">
                    <asp:TextBox ID="txtIDs" TextMode="MultiLine" Rows="50" runat="server" Width="99%"></asp:TextBox></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Button ID="btnPublish" runat="server" Text="Get Field Value" OnClick="btnPublish_Click" /></td>
            </tr>
            <tr>
                <td colspan="2" class="red-bg">
                    <asp:Label ID="lblError" runat="server"></asp:Label>
                </td>
                
            </tr>
            <tr>
                <td>
                    <asp:GridView ID="grdLanguageReport" CssClass="table-style-three" runat="server"></asp:GridView>
                </td>
            </tr>
        </table>

    </form>
</body>
</html>
