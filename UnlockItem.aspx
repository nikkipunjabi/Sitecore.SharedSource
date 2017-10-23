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
    <title>Lock/Unlock Children</title>

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
                Response.Redirect("login.aspx?returnUrl=UnlockItem.aspx");
            }
        }

        protected void btnLockAll_Click(object sender, EventArgs e)
        {
            int i = 0;
            try
            {                
                foreach (ListItem lang in chkLang.Items)
                {
                    if (lang.Selected)
                    {

                        Database db = Database.GetDatabase("master");
                        Item item = db.GetItem(txtID.Text, Language.Parse(lang.Value));
                        if (item.Access.CanWriteLanguage() && (!item.Locking.IsLocked()))
                        {
                            item.Editing.BeginEdit();
                            item.Locking.Lock();
                            item.Editing.EndEdit();
                            i++;
                        }

                        foreach (Item child in item.Axes.GetDescendants())
                        {
                            if (child.Access.CanWriteLanguage() && (!child.Locking.IsLocked()))
                            {
                                child.Editing.BeginEdit();
                                child.Locking.Lock();
                                child.Editing.EndEdit();
                                i++;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = ex.ToString();
            }
            lblMessage.Text = "Locked total " + i + " item(s)";
        }

        protected void btnUnLockAll_Click(object sender, EventArgs e)
        {
            int i = 0;
            try
            {
                foreach (ListItem lang in chkLang.Items)
                {
                    if (lang.Selected)
                    {

                        Database db = Database.GetDatabase("master");
                        Item item = db.GetItem(txtID.Text, Language.Parse(lang.Value));

                        if (item.Access.CanWriteLanguage() && item.Locking.IsLocked())
                        {
                            item.Editing.BeginEdit();
                            item.Locking.Unlock();
                            item.Editing.EndEdit();
                            i++;
                        }

                        foreach (Item child in item.Axes.GetDescendants())
                        {
                            if (child.Access.CanWriteLanguage() && child.Locking.IsLocked())
                            {
                                child.Editing.BeginEdit();
                                child.Locking.Unlock();
                                child.Editing.EndEdit();
                                i++;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = ex.ToString();
            }
            lblMessage.Text = "Unlocked total " + i + " item(s)";
        }

    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Lock/Unlock Bulk Items</h2>
        <table class="table-style-three">
            <tr>
                <td colspan="2" style="vertical-align: top">
                   Parent Item Path: <asp:TextBox ID="txtID" Width="400px" runat="server"></asp:TextBox></td>
                <td style="vertical-align: top">
                    <asp:CheckBoxList ID="chkLang" runat="server">
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
                        <asp:ListItem Value="zh-CN">Chinese</asp:ListItem>
						<asp:ListItem Value="hu">Hungarian</asp:ListItem>             
						<asp:ListItem Value="da">Danish</asp:ListItem>             
						<asp:ListItem Value="ro">Romanian</asp:ListItem>             
						<asp:ListItem Value="no">Norwegian</asp:ListItem>             
						<asp:ListItem Value="fi">Finnish</asp:ListItem>
                    </asp:CheckBoxList>
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Button ID="btnLockAll" runat="server" Text="Lock All" OnClick="btnLockAll_Click" /></td>
                <td colspan="2">
                    <asp:Button ID="btnUnlockAll" runat="server" Text="Unlock All" OnClick="btnUnLockAll_Click" /></td>
            </tr>
            <tr>
                <td colspan="3">
                    <asp:Label ID="lblMessage" runat="server"></asp:Label>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
