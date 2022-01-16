*** Settings ***
Documentation     Orders robots for each customer from RobotSpareBin Industries Inc.
...               Save the order HTML receipt as a PDF file.
...               Save the screenshot of the ordered robot.
...               Embed the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Robocorp.WorkItems
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocloud.Secrets
Resource          tasks.robot

*** Tasks ***
RoboCorp Level-II Task
    Take Input from user & Download Input File
    Open website
    Popup Close
    Enter all Data from Excel
    Create Zip File
    Close Browser

*** Keywords ***
Take Input from user & Download Input File
    ${csv_url}=    Get Value From User    Please enter the csv url
    Download    ${csv_url}

Open website
    ${website}=    Get Secret    websiteurl
    Open Available Browser    ${website}[url]
    Maximize Browser Window

Enter all Data from Excel
    ${order-reps}=    Read table from CSV    orders.csv    header=True
    FOR    ${order-reps}    IN    @{order-reps}
        Input order for one client    ${order-reps}
        Preview Robot
        Wait Until Element Is Visible    id:robot-preview-image
        Sleep    3 seconds
        Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}Task_Files${/}Robot_Screenshots${/}Robot_${order-reps}[Order number].png
        Click Button When Visible    order
        Check Order Button Clicked True
        Wait Until Element Is Visible    id:receipt
        Sleep    3 seconds
        ${order-receipt}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${order-receipt}    ${OUTPUT_DIR}${/}Task_Files${/}HTML_Receipts${/}Receipt_${order-reps}[Order number].pdf
        ${receipt-pdf}=    Open Pdf    ${OUTPUT_DIR}${/}Task_Files${/}HTML_Receipts${/}Receipt_${order-reps}[Order number].pdf
        ${robo-png}=    Create List    ${OUTPUT_DIR}${/}Task_Files${/}HTML_Receipts${/}Receipt_${order-reps}[Order number].pdf
        ...    ${OUTPUT_DIR}${/}Task_Files${/}Robot_Screenshots${/}Robot_${order-reps}[Order number].png
        Add Files To Pdf    ${robo-png}    ${OUTPUT_DIR}${/}Task_Files${/}Embeded_PDFs${/}Receipt_${order-reps}[Order number].pdf
        Go for Next Robot
    END

Input order for one client
    [Arguments]    ${order-reps}
    Select From List By Index    head    ${order-reps}[Head]
    Select Radio Button    body    id-body-${order-reps}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order-reps}[Legs]
    Input Text    address    ${order-reps}[Address]

Popup Close
    Wait Until Page Contains Element    id:root
    Click Button    Yep

Preview Robot
    Click Button    preview

Close & Restart Browser
    Close Browser
    Open website
    Continue For Loop

Check Order Button Clicked True
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        Run Keyword If    '${alert}'=='True'    Click Button    //button[@id="order"]
        Exit For Loop If    '${alert}'=='False'
    END
    Run Keyword If    '${alert}'=='True'    Close & Restart Browser

Go for Next Robot
    Click Button When Visible    order-another
    Popup Close

Create Zip File
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Task_Files${/}Embeded_PDFs    Task_Files.zip    recursive=True
