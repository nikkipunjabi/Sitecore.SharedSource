﻿<%@ Page Language="C#" AutoEventWireup="true" Debug="true" %>

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
            if (Sitecore.Context.User.IsAdministrator == false)
            {
                Response.Redirect("login.aspx?returnUrl=SyncMailjet.aspx");
            }
        }

        protected void btnSyncTables_Click(object sender, EventArgs e)
        {
            // Create new stopwatch.
            Stopwatch stopwatch = new Stopwatch();

            // Begin timing.
            stopwatch.Start();



            //ListDictionary Tables = new ListDictionary();
            ////Tables.Add("Users", "7803");
            ////Tables.Add("VDDownloadsInfos", "7788");
            //Tables.Add("NewsletterSubscription", "9201");
            ////Tables.Add("DSSFestivalFans", "7787");

            //DB to get the market value from Item: {29F516DA-C1D6-4E34-97E1-AFAD25C93A45}
            Database db = Database.GetDatabase("master");

            var marketItem = db.GetItem("{E3445ED7-8EE4-4CF9-A71D-B2A057755E2C}");

            string _urlParamsToParse = marketItem["Countries"];
            NameValueCollection nameValueCollection = Sitecore.Web.WebUtil.ParseUrlParameters(_urlParamsToParse);

            //foreach (string nv in nameValueCollection)
            //{
            //    if (nv.Equals(usercountry))
            //    {
            //        userMarket = nameValueCollection[nv];
            //        break;
            //    }
            //}


            List<string> MailChimpTableIDs = new List<string>();

            StringBuilder build = new StringBuilder();
            //Building an HTML string to render and show to a user
            StringBuilder html = new StringBuilder();

            bool isLastRecordForRequest = false;

            foreach (string nv in nameValueCollection)
            {
                html.AppendLine("<br /> <br />" + nv.ToString() + "<br /> <br />");
                //var strSelectQuery = @"SELECT * FROM " + nv.ToString() + " WHERE [Email] like 'VDQA02@dtcmdomain.com'" ;
                var strSelectQuery = @"SELECT * FROM " + nv.ToString();
                var TableData = GetDataTable(strSelectQuery, "external");
                //List<users> MyUsers = new List<users>();
                StringBuilder jsonStringList = new StringBuilder();

                //Base Json Text
                jsonStringList.AppendLine("{\"ContactsLists\":[ { \"ListID\": " + nameValueCollection[nv.ToString()] + ", \"action\": \"addnoforce\" } ], \"Contacts\":[ ");

                //Backup
                //jsonStringList.AppendLine("{\"ContactsLists\":[ { \"ListID\": 7803, \"action\": \"addnoforce\" } ], \"Contacts\":[ { \"Email\": \"jimsmith1234@example.com\", \"Name\": \"Jim\", \"Properties\": { \"country\": \"Dubai\", \"phone\": \"055555\" } }, { \"Email\": \"janetdoe1234@example.com\", \"Name\": \"Janet\", \"Properties\": { \"country\": \"value\", \"phone\": \"value2\" } } ] }");

                if (TableData.Rows.Count > 0)
                {
                    int rowCount = TableData.Rows.Count;
                    int currentCount = 0;

                    int currentRowCount = 0;

                    Dictionary<string, string> keyvalues = new Dictionary<string, string>();
                    keyvalues.Add("five-days", "5 Days In Dubai");
                    keyvalues.Add("24-hours-in-dubai", "1 Day In Dubai");
                    keyvalues.Add("dubai-in-48-hours", "2 Days In Dubai");
                    keyvalues.Add("2-day", "2 Days In Dubai");

                    keyvalues.Add("summer", "Summer In Dubai");
                    keyvalues.Add("winter", "Winter In Dubai");

                    keyvalues.Add("family", "Family");

                    keyvalues.Add("stopover", "Stopover");
                    keyvalues.Add("layover", "Stopover");

                    keyvalues.Add("adventure", "Adventure");
                    keyvalues.Add("cycling", "Adventure");
                    keyvalues.Add("action", "Adventure");
                    keyvalues.Add("desert", "Adventure");
                    keyvalues.Add("hatta", "Adventure");
                    keyvalues.Add("sport", "Adventure");

                    keyvalues.Add("heritage", "Culture");
                    keyvalues.Add("cultural", "Culture");

                    keyvalues.Add("/deals-and-offers", "Deals");
                    keyvalues.Add("/retail-offers", "Deals");

                    keyvalues.Add("/dsf", "Festivals");
                    keyvalues.Add("/dubai-shopping-festival", "Festivals");
                    keyvalues.Add("/dff", "Festivals");
                    keyvalues.Add("/dubai-food-festival", "Festivals");
                    keyvalues.Add("/dss", "Festivals");
                    keyvalues.Add("ramadan", "Festivals");
                    keyvalues.Add("eid", "Festivals");
                    keyvalues.Add("national-day", "Festivals");
                    keyvalues.Add("new-year", "Festivals");
                    keyvalues.Add("/festivals/", "Festivals");

                    keyvalues.Add("/events", "Events");

                    keyvalues.Add("shah-rukh", "SRK");

                    keyvalues.Add("cuisine", "Dining");
                    keyvalues.Add("dining", "Dining");
                    keyvalues.Add("foodie", "Dining");

                    keyvalues.Add("shop-the", "Shopping");
                    keyvalues.Add("shopping", "Shopping");
                    keyvalues.Add("shop-in-dubai", "Shopping");

                    keyvalues.Add("you-me-dubai", "Couples");
                    keyvalues.Add("romantic", "Couples");
                    keyvalues.Add("romance", "Couples");
                    keyvalues.Add("couple", "Couples");

                    keyvalues.Add("luxury", "Luxury");

                    keyvalues.Add("reward", "Beaches And Relaxation");
                    keyvalues.Add("beach", "Beaches And Relaxation");
                    keyvalues.Add("therapy", "Beaches And Relaxation");
                    keyvalues.Add("beaten-path", "Beaches And Relaxation");

                    keyvalues.Add("business", "Business");
                    keyvalues.Add("meet-in-dubai", "Business");

                    keyvalues.Add("theme", "Theme Parks");

                    keyvalues.Add("dubai-essentials", "Travel Planning");
                    keyvalues.Add("tour", "Travel Planning");
                    keyvalues.Add("cruise-dubai", "Travel Planning");


                    foreach (DataRow dataRow in TableData.Rows)
                    {
                        if (currentRowCount < 5000)
                        {
                            try
                            {
                                currentRowCount = currentRowCount + 1;
                                currentCount = currentCount + 1;

                                if (currentRowCount == 4999 || currentCount == rowCount)
                                {
                                    isLastRecordForRequest = true;
                                }

                                if (nv.ToString().ToLower().Equals("hiddengemlikes"))
                                {
                                    jsonStringList.AppendLine("{ \"Email\": \"" + dataRow["EmailId"].ToString().Trim() + "\", \"Properties\": { \"userdomain\": \"" + dataRow["Domain"].ToString().Trim() + "\" , \"interest2\": \"Dining\" } },");
                                }
                                else if (nv.ToString().ToLower().Equals("users"))
                                {
                                    string userLanguage = GetUserLanguageFromURL("", dataRow["Language"].ToString().ToLower(), true);
                                    jsonStringList.AppendLine("{ \"Email\": \"" + dataRow["Email"].ToString().Trim() + "\", \"Name\": \"" + dataRow["FirstName"].ToString().Trim() + " " + dataRow["LastName"].ToString().Trim() + "\", \"Properties\": { \"country\": \"" + dataRow["Country"].ToString().Trim() + "\", \"firstname\": \"" + dataRow["FirstName"].ToString().Trim() + "\", \"lastname\": \"" + dataRow["LastName"].ToString().Trim() + "\" , \"phone\": \"" + dataRow["PhoneNumber"].ToString().Trim() + "\", \"phonecountrycode\": \"" + dataRow["CountryCode"].ToString().Trim() + "\" , \"language\": \"" + userLanguage + "\" , \"createddate\": \"" + dataRow["CreatedDate"].ToString().Trim() + "\" } },");
                                }
                                else if (nv.ToString().ToLower().Equals("vddownloadsinfos"))
                                {
                                    string userInterest = GetUserInterestFromURL(dataRow["URL"].ToString().ToLower(), dataRow["Domain"].ToString().Trim(), keyvalues);
                                    string userLanguage = GetUserLanguageFromURL(dataRow["URL"].ToString().ToLower(), "");
                                    string userMarket = GetUserMarketFromCountry(dataRow["Country"].ToString(), db);

                                    jsonStringList.AppendLine("{ \"Email\": \"" + dataRow["Email"].ToString().Trim() + "\", \"Name\": \"" + dataRow["Name"].ToString().Trim() + "\", \"Properties\": { \"country\": \"" + dataRow["Country"].ToString().Trim() + "\", \"market\": \"" + userMarket + "\" , \"firstname\": \"" + dataRow["Name"].ToString().Trim() + "\" , \"userdomain\": \"" + dataRow["Domain"].ToString().Trim() + "\" , \"interest1\": \"" + userInterest + "\" ,  \"url\": \"" + dataRow["URL"].ToString() + "\" , \"language\": \"" + userLanguage + "\" , \"createddate\": \"" + dataRow["CreatedDate"].ToString().Trim() + "\" } },");
                                }
                                else if (nv.ToString().ToLower().Equals("newslettersubscription"))
                                {
                                    string userInterest = GetUserInterestFromURL(dataRow["URL"].ToString().ToLower(), dataRow["Domain"].ToString().Trim(), keyvalues);
                                    string userLanguage = GetUserLanguageFromURL(dataRow["URL"].ToString().ToLower(), dataRow["Language"].ToString());
                                    string userMarket = GetUserMarketFromCountry(dataRow["Country"].ToString(), db);

                                    jsonStringList.AppendLine("{ \"Email\": \"" + dataRow["Email"].ToString().Trim() + "\", \"Name\": \"" + dataRow["FullName"].ToString().Trim() + "\", \"Properties\": { \"country\": \"" + dataRow["Country"].ToString().Trim() + "\", \"interest2\": \"" + userInterest + "\" , \"market\": \"" + userMarket + "\" , \"firstname\": \"" + dataRow["FullName"].ToString().Trim() + "\" , \"userdomain\": \"" + dataRow["Domain"].ToString().Trim() + "\" , \"language\": \"" + userLanguage + "\" , \"url\": \"" + dataRow["URL"].ToString() + "\" , \"createddate\": \"" + dataRow["CreatedDate"].ToString().Trim() + "\" } },");
                                }
                                else if (nv.ToString().ToLower().Equals("dssfestivalfans"))
                                {
                                    jsonStringList.AppendLine("{ \"Email\": \"" + dataRow["Email"].ToString().Trim() + "\", \"Name\": \"" + dataRow["FullName"].ToString().Trim() + "\", \"Properties\": { \"country\": \"" + dataRow["Country"].ToString().Trim() + "\", \"firstname\": \"" + dataRow["FullName"].ToString().Trim() + "\" , \"createddate\": \"" + dataRow["CreatedDate"].ToString().Trim() + "\" } },");
                                }
                                

                                if (isLastRecordForRequest)
                                {
                                    isLastRecordForRequest = false;
                                    currentRowCount = 0;
                                    jsonStringList.Append("] }");
                                    CreateWebRequest(ref jsonStringList, ref html);
                                    jsonStringList.Clear();
                                    jsonStringList.AppendLine("{\"ContactsLists\":[ { \"ListID\": " + nameValueCollection[nv.ToString()] + ", \"action\": \"addnoforce\" } ], \"Contacts\":[ ");

                                    html.AppendLine("<br /> Procceeding with Next Request<br />");
                                }
                            }
                            catch (Exception ex)
                            {
                                //do nothing
                                html.AppendLine(ex.StackTrace.ToString());
                                Sitecore.Diagnostics.Log.Info("Something wrong: " + ex.StackTrace, this);
                            }
                        }
                    }
                }
            }

            // Stop timing.
            stopwatch.Stop();

            // Write result.
            html.AppendLine("<br/> <br/> <br/> Time elapsed: " + stopwatch.Elapsed);
            Sitecore.Diagnostics.Log.Info("Sync Mailjet Time elapsed: " + stopwatch.Elapsed, this);

            lblSummary.Text = html.ToString();

        }

        public void CreateWebRequest(ref StringBuilder jsonStringList, ref StringBuilder html)
        {
            //Sitecore.Diagnostics.Log.Info(jsonStringList.ToString().Trim(), this);
            var webRequest = (HttpWebRequest)WebRequest.Create("https://api.mailjet.com/v3/REST/contact/managemanycontacts");
            webRequest.Method = "POST";
            webRequest.ContentType = "application/json";
            webRequest.Headers.Add("Authorization", "Basic Z");
            webRequest.Timeout = 500000;

            //https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-send-data-using-the-webrequest-class
            Stream dataStream = webRequest.GetRequestStream();
            byte[] byteArray = Encoding.UTF8.GetBytes(jsonStringList.ToString().Trim());
            dataStream.Write(byteArray, 0, byteArray.Length);
            dataStream.Close();

            try
            {
                using (var webResponse = (HttpWebResponse)webRequest.GetResponse())
                {
                    using (var stream = webResponse.GetResponseStream())
                    {
                        if (stream != null)
                        {
                            using (var memoryStream = new MemoryStream())
                            {
                                using (var reader = new StreamReader(stream, Encoding.UTF8))
                                {
                                    var jSon = Serialize<string>(reader.ReadToEnd());
                                    html.AppendLine(jSon);
                                }
                            }
                        }
                    }
                }
            }
            catch (WebException ex)
            {
                html.Append("<br>Error Status: " + ex.Status + "<br>");
                html.Append("<br>Error Message: " + ex.Message + "<br>");
                using (var stream = ex.Response.GetResponseStream())
                using (var reader = new StreamReader(stream))
                {
                    html.Append("<br>Response String: " + reader.ReadToEnd() + "<br>");
                }

                html.Append("<br />Json String Error: " + jsonStringList.ToString().Trim() + "<br />");

                Sitecore.Diagnostics.Log.Info("Something wrong in request: " + ex.StackTrace, this);

            }
        }

        public static string Serialize<T>(T obj)
        {
            DataContractJsonSerializer serializer = new DataContractJsonSerializer(obj.GetType());
            using (MemoryStream ms = new MemoryStream())
            {
                serializer.WriteObject(ms, obj);
                return Encoding.Default.GetString(ms.ToArray());
            }
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
                //Sitecore.Diagnostics.Log.Error("There is an error in GetDataTable", ex, this);
            }
            return genericTable;
        }

        private string GetUserInterestFromURL(string url, string domain, Dictionary<string, string> dict)
        {
            url = url.ToLower();

            string userInterset = string.Empty;

            if (domain.Equals("Press Download"))
            {
                userInterset = "Press Releases";
            }
            else if (domain.Equals("InteractiveMap"))
            {
                userInterset = "Map Of Dubai";
            }
            else if (domain.Equals("DC APP"))
            {
                userInterset = "DC APP";
            }

            if (string.IsNullOrEmpty(userInterset))
            {

                foreach (var key in dict)
                {
                    if (url.Contains(key.Key))
                    {
                        userInterset = key.Value;
                        break;
                    }
                }

                if (string.IsNullOrEmpty(userInterset))
                {
                    if (url.Contains("/itineraries") || url.Contains("/travel-planning"))
                    {
                        userInterset = "Travel Planning";
                    }
                }

                if (string.IsNullOrEmpty(userInterset))
                {
                    userInterset = "Generic";
                }
            }

            return userInterset;
        }

        private string GetUserLanguageFromURL(string url, string language, bool isUser = false)
        {
            if (string.IsNullOrWhiteSpace(language) && string.IsNullOrWhiteSpace(url))
            {
                return "en";
            }

            if (!string.IsNullOrWhiteSpace(language) && language.Length > 2)
            {
                if (language.ToLower().Contains("arabic"))
                    return "ar";
                else if (language.ToLower().Contains("russian"))
                    return "ru";
                else if (language.ToLower().Contains("italian"))
                    return "it";
                else if (language.ToLower().Contains("french"))
                    return "fr";
                else if (language.ToLower().Contains("spanish"))
                    return "es";
                else if (language.ToLower().Contains("chinese"))
                    return "zh-cn";
                else if (language.ToLower().Contains("polish"))
                    return "pl";
                else if (language.ToLower().Contains("german"))
                    return "de";
                else if (language.ToLower().Contains("azerbaijani") || language.ToLower().Contains("azeri"))
                    return "az";
                else if (language.ToLower().Contains("portuguese"))
                    return "pt";
                else if (language.ToLower().Contains("indonesian"))
                    return "id";
                else if (language.ToLower().Contains("dutch"))
                    return "nl";
                else if (language.ToLower().Contains("swedish"))
                    return "sv";
                else if (language.ToLower().Contains("portuguese"))
                    return "pt";
                else if (language.ToLower().Contains("japanese"))
                    return "ja";
                else if (language.ToLower().Contains("korean"))
                    return "ko";
                else if (language.ToLower().Contains("ukrainian"))
                    return "uk";
                else if (language.ToLower().Contains("czech"))
                    return "cs";
                else if (language.ToLower().Contains("cantonese"))
                    return "hk";
                else if (language.ToLower().Contains("danish"))
                    return "da";
                else if (language.ToLower().Contains("hungarian"))
                    return "hu";
                else if (language.ToLower().Contains("norwegian"))
                    return "no";
                else if (language.ToLower().Contains("finnish"))
                    return "fi";
                else
                    return "en";
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(url))
                {
                    var splittedURL = url.Split('/');
                    if (splittedURL != null && splittedURL.Count() > 1)
                    {
                        if (splittedURL[1].Length >= 2)
                        {
                            return splittedURL[1].Substring(0, 2).ToLower();
                        }
                        else
                        {
                            return "en";
                        }
                    }
                    else
                    {
                        return "en";
                    }
                }
                else return "en";
            }
        }

        private string GetUserMarketFromCountry(string usercountry, Database db)
        {
            string userMarket = "Anonymous";

            if (string.IsNullOrWhiteSpace(usercountry) || usercountry.Length > 2)
            {
                return userMarket;
            }

            var marketItem = db.GetItem("{29F516DA-C1D6-4E34-97E1-AFAD25C93A45}");

            string _urlParamsToParse = marketItem["Countries"];
            NameValueCollection nameValueCollection = Sitecore.Web.WebUtil.ParseUrlParameters(_urlParamsToParse);

            foreach (string nv in nameValueCollection)
            {
                if (nv.Equals(usercountry))
                {
                    userMarket = nameValueCollection[nv];
                    break;
                }
            }

            return userMarket;
        }

        public class users
        {
            public string Username { get; set; }
            public string Password { get; set; }
            public string FirstName { get; set; }
            public string LastName { get; set; }
            public string EmailAddress { get; set; }

        }

    </script>

</head>
<body>
    <form id="form1" runat="server">
        <h2>Sync Site Users with Mailjet!</h2>
        <h4>Use this tool to sync all the Website Users with Mailjet</h4>
        <table>
            <tr>
                <td>
                    <asp:Button ID="btnSyncUsers" runat="server" Text="Sync Tables" OnClick="btnSyncTables_Click" /></td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="lblSummary" CssClass="positionAbsolute" runat="server"></asp:Label></td>
            </tr>
        </table>
    </form>
</body>
</html>
