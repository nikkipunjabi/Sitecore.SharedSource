<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="Sitecore.Collections" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="Sitecore.Data.Fields" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Export Items</title>

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
                Response.Redirect("login.aspx?returnUrl=exportitem.aspx");
            }
        }

        protected void btnGetReport_Click(object sender, EventArgs e)
        {
            try
            {
                string path = txtPath.Text;
                string DB = drpDB.SelectedItem.Value;
                Database db = Database.GetDatabase(DB);
                Language lang = Sitecore.Globalization.Language.Parse(txtLang.Text);
                Item parent = db.GetItem(path, lang);
                tb = new DataTable();
                tb.Columns.Add("Item Path");
                int rowNumber = 0;

                List<Item> childItems = new List<Item>();
                if (chkbxDescendant.Checked)
                {
                    childItems = parent.Axes.GetDescendants().Where(i => i.TemplateName == txtTemplateName.Text).ToList();
                }
                else
                {
                    childItems = parent.GetChildren().Where(i => i.TemplateName == txtTemplateName.Text).ToList();
                }

                foreach (Item childItem in childItems)
                {
                    // Ucomment below section for date filter *************
                    //DateTime dtFrom = Sitecore.DateUtil.ParseDateTime(childItem["Event From"],DateTime.MinValue);
                    //DateTime dtTo = Sitecore.DateUtil.ParseDateTime(childItem["Event To"],DateTime.MaxValue);

                    //DateTime txtFrom = DateTime.Parse(txtEventFrom.Text);
                    //DateTime txtTo = DateTime.Parse(txtEventTo.Text);

                    //if ((dtFrom >= txtFrom && dtFrom <= txtTo) || (dtTo >= txtFrom && dtTo <=txtTo))
                    //{
                    // Ucomment above section for date filter ***************
                    DataRow itemRow = tb.NewRow();
                    //int colNumber = 0;  

                    if (!string.IsNullOrEmpty(txtFields.Text))
                    {
                        string[] arrFieldNames = txtFields.Text.Split(new string[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);

                        foreach (string strFieldName in arrFieldNames)
                        {
                            var field = childItem.Fields[strFieldName];
                            if (field != null)
                            {
                                if (rowNumber == 0)
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

                                itemRow[strFieldName] = childItem.Fields[strFieldName].GetValue(true);
                            }

                        }

                        itemRow["Item Path"] = childItem.Paths.Path;
                        tb.Rows.Add(itemRow);
                        rowNumber++;

                    }
                    else
                    {
                        childItem.Fields.ReadAll();
                        foreach (Field fld in childItem.Fields)
                        {
                            if (!fld.Name.StartsWith("__"))
                            {
                                if (rowNumber == 0)
                                {
                                    if (tb.Columns.Contains(fld.Name))
                                    {
                                        tb.Columns.Add(fld.SectionDisplayName + "_" + fld.Name + Guid.NewGuid().ToString());
                                    }
                                    else
                                    {
                                        tb.Columns.Add(fld.Name);
                                    }
                                }
                            }
                        }
                        rowNumber++;

                        foreach (Field fld in childItem.Fields)
                        {
                            if (!fld.Name.StartsWith("__"))
                            {
                                if (tb.Columns[fld.Name] != null)
                                {
                                    itemRow["Item Path"] = childItem.Paths.Path;
                                    itemRow[fld.Name] = fld.GetValue(true);
                                }
                            }
                        }

                        tb.Rows.Add(itemRow);
                    }


                    //}

                }

                lblCount.Text = "Total items: " + tb.Rows.Count.ToString();
                grdLanguageReport.DataSource = tb;
                grdLanguageReport.DataBind();
                //Session.Add("Data", tb);
            }
            catch (Exception ex)
            {
                lblCount.Text = ex.ToString();
            }
        }

        protected void ExportToExcel(object sender, EventArgs e)
        {
            string attachment = "attachment; filename=Report.xls";
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
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <h2>Export Item Tool - Visit Dubai</h2>
        <table>
            <tr>
                <td>Parent Item Path:<asp:TextBox ID="txtPath" Width="500px" runat="server"></asp:TextBox></td>
                <td>Include Descendants<asp:CheckBox ID="chkbxDescendant" runat="server" /></td>
                <td>Template Name:<asp:TextBox ID="txtTemplateName" Width="500px" runat="server"></asp:TextBox></td>
                <td>Fields:<asp:TextBox ID="txtFields" Width="300px" TextMode="MultiLine" runat="server" ToolTip="Optional"></asp:TextBox></td>
                <%--<td>Event From:<asp:TextBox ID="txtEventFrom" runat="server"></asp:TextBox></td>
                <td>Event To:<asp:TextBox ID="txtEventTo" runat="server"></asp:TextBox></td>--%>
                <td>Language:<asp:TextBox ID="txtLang" Text="en" runat="server"></asp:TextBox></td>
                <td>Database:<asp:DropDownList ID="drpDB" runat="server">
                    <asp:ListItem Text="Master" Value="master"></asp:ListItem>
                    <asp:ListItem Text="Stage" Value="stage"></asp:ListItem>
                    <asp:ListItem Text="Web" Value="web"></asp:ListItem>
                </asp:DropDownList></td>
            </tr>
            <tr>
                <td>
                    <asp:Button ID="btnGetReport" Text="Export" runat="server" OnClick="btnGetReport_Click" />
                    <%--<asp:Button ID="btnDownload" runat="server" Text="Download Report" OnClick="ExportToExcel" />--%>
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblCount" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td>&nbsp;</td>
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
