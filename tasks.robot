*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Excel.Files
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Robocloud.Secrets
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    course2
    Open Available Browser      url=${secret}[link2]    browser_selection=vivaldi,firefox
    #Open Available Browser  url=https://robotsparebinindustries.com/#/robot-order  browser_selection=vivaldi,firefox

*** Keywords ***
Get orders

    Create Form    Please write the link of the table
    Add Text Input    Write link:    link
    &{response}=    Request Response
    Download     ${response}[link]    overwrite=True
    
    #Download     https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${tabla}=    Read Table From Csv    orders.csv    header=True
    [Return]    ${tabla}

*** Keywords ***
Close the annoying modal
    Click Element When Visible  xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[3]

*** Keywords ***
Fill the form
    [Arguments]    ${head}    ${body}   ${legs}    ${address}
    Wait Until Page Contains Element    id:head
    Select From List By Value    head    ${head}
    ${body_locator}=    Set Variable    xpath://*[@id="id-body-${body}"]
    Click Element When Visible    locator=${body_locator}
    ${legs_locator}=    Set Variable    xpath://*[@class="form-control"]
    Input Text    ${legs_locator}    ${legs}
    ${address_locator}=    Set Variable    xpath://*[@id="address"]
    Input Text    ${address_locator}    ${address}

*** Keywords ***
Preview the robot
    Click Element When Visible  xpath://*[@id="preview"]

*** Keywords ***
Submit the order
    ${locator}=    Set Variable    xpath://*[@id="root"]/div/div[1]/div/div[1]/div
    Wait Until Page Contains Element    id:order    timeout=10s
    FOR    ${i}    IN RANGE    9999999
        Wait Until Keyword Succeeds    5x    1s    Click Element When Visible  id:order
        ${Receipt}=    Is Element Visible    id:receipt
        ${result}=    Evaluate    ${Receipt} == True
        Exit For Loop If    ${result}
    END

*** Keywords ***
Store the receipt as a PDF file 
    [Arguments]    ${orden}
    ${locator}=    Set Variable    id:receipt
    ${recibo2}=    Get Element Attribute    ${locator}    outerHTML
    Html To Pdf    ${recibo2}    ${CURDIR}${/}output/receipt/robot-${orden}.pdf
    [Return]    ${CURDIR}${/}output/receipt/robot-${orden}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${orden}
    Wait Until Page Contains Element    id:robot-preview-image
    ${locator}=    Set Variable    xpath://*[@id="robot-preview-image"]/img[1]
    Wait Until Page Contains Element    ${locator}
    ${locator}=    Set Variable    xpath://*[@id="robot-preview-image"]/img[2]
    Wait Until Page Contains Element    ${locator}
    ${locator}=    Set Variable    xpath://*[@id="robot-preview-image"]/img[3]
    Wait Until Page Contains Element    ${locator}
    ${robot_image}=    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output/photos/robot-${orden}.png
    [Return]    ${CURDIR}${/}output/photos/robot-${orden}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    Close Pdf    ${pdf}

*** Keywords ***
Go to order another robot
    Click Element When Visible    xpath://*[@id="order-another"]

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output/receipt  receipts.zip
    ${files_to_move}=    Create List    receipts.zip
    Move Files    ${files_to_move}    output    overwrite=True

*** Tasks ***
Order robots from RobotSpareBin Industries Inc

    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}[Head]    ${row}[Body]    ${row}[Legs]    ${row}[Address]
         Preview the robot
         Submit the order
         ${pdf}=    Store the receipt as a PDF file   ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser 
