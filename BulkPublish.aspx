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
                Response.Redirect("login.aspx?returnUrl=bulkpublish.aspx");
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            chkall.Attributes.Add("onchange", "javascript: Selectall();");
            chkBoxSelectAllCore.Attributes.Add("onchange", "javascript: SelectallCore();");
            chkBoxSelectAllOthers.Attributes.Add("onchange", "javascript: SelectallOthers();");
            chkBoxSelectAllNewLanguages.Attributes.Add("onchange", "javascript: SelectallNewLanguages();");
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
                    foreach (ListItem lang in chkLangCore.Items)
                    {
                        if (lang.Selected)
                        {
                            PublishItem(i, isSubitem, DB, lang.Value);
                            sb.Append("Item published:").Append(i.ID).Append("Language: ").Append(lang.Value).Append("<br/>");
                            string log = string.Format("Item Published By {0} Using Tool -- Item Path: {1} -- Item ID: {2} -- Language: {3} -- SubItems: {4}", Sitecore.Context.User.Name, i.Paths.FullPath, i.ID, lang.Value, isSubitem.ToString());
                            Sitecore.Diagnostics.Log.Info(log, this);
                        }
                    }
                    foreach (ListItem lang in chklangOthers.Items)
                    {
                        if (lang.Selected)
                        {
                            PublishItem(i, isSubitem, DB, lang.Value);
                            Sitecore.Diagnostics.Log.Info("Item Published Using Tool - Language: " + lang.Value, this);
                            sb.Append("Item published:").Append(i.ID).Append("Language: ").Append(lang.Value).Append("<br/>");
                            string log = string.Format("Item Published By {0} Using Tool -- Item Path: {1} -- Item ID: {2} -- Language: {3}", Sitecore.Context.User.Name, i.Paths.FullPath, i.ID, lang.Value);
                            Sitecore.Diagnostics.Log.Info(log, this);
                        }
                    }
                    foreach (ListItem lang in chkNewLanguages.Items)
                    {
                        if (lang.Selected)
                        {
                            PublishItem(i, isSubitem, DB, lang.Value);
                            Sitecore.Diagnostics.Log.Info("Item Published Using Tool - Language: " + lang.Value, this);
                            sb.Append("Item published:").Append(i.ID).Append("Language: ").Append(lang.Value).Append("<br/>");
                            string log = string.Format("Item Published By {0} Using Tool -- Item Path: {1} -- Item ID: {2} -- Language: {3}", Sitecore.Context.User.Name, i.Paths.FullPath, i.ID, lang.Value);
                            Sitecore.Diagnostics.Log.Info(log, this);
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
                <td style="width: 20%">Publish:<asp:DropDownList ID="drpIsSubItem" runat="server">
                    <asp:ListItem Text="Without SubItem" Value="0"></asp:ListItem>
                    <asp:ListItem Text="With SubItem" Value="1"></asp:ListItem>
                </asp:DropDownList></td>
                <td style="width: 90%">Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="Web" Value="web"></asp:ListItem>
                </asp:DropDownList></td>
            </tr>
            <tr>
                <td style="vertical-align: top" class="chkBoxes">
                    <h3>Core Languages</h3>
                    <asp:CheckBox runat="server" ID="chkBoxSelectAllCore" Visible="true" Text="Select/Deselect All Core" CssClass="JchkAll" />
                    <div class="chkBoxesCore">
                        <asp:CheckBoxList ID="chkLangCore" runat="server">
                            <asp:ListItem Value="en">English</asp:ListItem>
                            <asp:ListItem Value="ar">Arabic</asp:ListItem>
                            <asp:ListItem Value="fr">French</asp:ListItem>
                            <asp:ListItem Value="ru">Russian</asp:ListItem>
                            <asp:ListItem Value="de">German</asp:ListItem>
                        </asp:CheckBoxList>
                    </div>
                    <h3>Languages</h3>
                    <asp:CheckBox runat="server" ID="chkBoxSelectAllOthers" Visible="true" Text="Select/Deselect All Other" CssClass="JchkAll" />
                    <div class="chkBoxesOthers">
                        <asp:CheckBoxList ID="chklangOthers" runat="server">
                            <asp:ListItem Value="id">Indonesian</asp:ListItem>
                            <asp:ListItem Value="az">Azeri</asp:ListItem>
                            <asp:ListItem Value="cs">Czech</asp:ListItem>
                            <asp:ListItem Value="es">Spanish</asp:ListItem>
                            <asp:ListItem Value="it">Italian</asp:ListItem>
                            <asp:ListItem Value="ja">Japanese</asp:ListItem>
                            <asp:ListItem Value="ko">Korean</asp:ListItem>
                            <asp:ListItem Value="nl">Dutch</asp:ListItem>
                            <asp:ListItem Value="pl">Polish</asp:ListItem>
                            <asp:ListItem Value="pt">Portuguese</asp:ListItem>
                            <asp:ListItem Value="sv">Swedish</asp:ListItem>
                            <asp:ListItem Value="uk">Ukrainian</asp:ListItem>
                            <asp:ListItem Value="hk">Cantonese</asp:ListItem>
                        </asp:CheckBoxList>
                    </div>
                    <h3>New Languages</h3>
                    <asp:CheckBox runat="server" ID="chkBoxSelectAllNewLanguages" Visible="true" Text="Select/Deselect All New Languages" CssClass="JchkAll" />
                    <div class="chkBoxesNewLanguages">
                        <asp:CheckBoxList ID="chkNewLanguages" runat="server">
                            <asp:ListItem Value="hu">Hungarian</asp:ListItem>
                            <asp:ListItem Value="da">Danish</asp:ListItem>
                            <asp:ListItem Value="ro">Romanian</asp:ListItem>
                            <asp:ListItem Value="no">Norwegian</asp:ListItem>
                            <asp:ListItem Value="fi">Finnish</asp:ListItem>
                        </asp:CheckBoxList>
                    </div>
                    <asp:CheckBox runat="server" ID="chkall" Visible="true" Text="Select/Deselect All" CssClass="JchkAll" />
                </td>
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
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
    <script type="text/javascript">
        function Selectall() {
            if ($('#<%= chkall.ClientID  %>').is(':checked')) {
                $(".chkBoxes :input").each(function () {
                    $(this).prop('checked', true);
                });
            }
            else {
                $(".chkBoxes :input").each(function () {
                    $(this).prop('checked', false);
                });
            }
        }

        function SelectallCore() {
            if ($('#<%= chkBoxSelectAllCore.ClientID  %>').is(':checked')) {
                $(".chkBoxesCore :input").each(function () {
                    $(this).prop('checked', true);
                });
            }
            else {
                $(".chkBoxesCore :input").each(function () {
                    $(this).prop('checked', false);
                });
            }
        }

        function SelectallOthers() {
            if ($('#<%= chkBoxSelectAllOthers.ClientID  %>').is(':checked')) {
                $(".chkBoxesOthers :input").each(function () {
                    $(this).prop('checked', true);
                });
            }
            else {
                $(".chkBoxesOthers :input").each(function () {
                    $(this).prop('checked', false);
                });
            }
        }

        function SelectallNewLanguages() {
            if ($('#<%= chkBoxSelectAllNewLanguages.ClientID  %>').is(':checked')) {
                $(".chkBoxesNewLanguages :input").each(function () {
                    $(this).prop('checked', true);
                });
            }
            else {
                $(".chkBoxesNewLanguages :input").each(function () {
                    $(this).prop('checked', false);
                });
            }
        }
    </script>
</body>
</html>
