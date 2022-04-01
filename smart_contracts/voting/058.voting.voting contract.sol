pragma solidity >=0.4.22 <0.7.0;

/** 
 * @title Designing a voting contract 
 * @dev Implements voting process for voting by students to decide Scholarship Winner(s) 
 */
contract Scholarship {
   
    struct Student {
        uint vote_possession; // Number of vote tickets possessed by each student. Vote is either assigned by Professor or is accumulated by receiving tickets from other students
        bool voteAssigned; // State of whether student being assigned vote ticket by professor, to determine whether the address belongs to a valid student
        uint voteCasted_count; // Number of times of voting, with maximum of 3
        uint timeOfFirstVoteCast; // Time between first vote casted by each student and Deadline, to help decide the earliest voter. The first voter will have the largest value.
    }

    address payable public professor; // The address of the Professor

    uint public scholarship; // Scholarship money to be allocated after voting
    
    uint public deadline; // Deadline of scholarship voting
    
    bool public isDeadlineSet; // To check whether Deadline set before voting starts
  
    mapping(address => Student) public students; // Each student's address is mapped to the student structured data with student's voting details
    
    address payable [] public voteAssignedList; // List (array) of students assigned 1 vote ticket by Professor
    
    address payable [] public winningStudent; // List (array) of scholarship winning student(s) BY VOTE COUNT
    
    uint public numberOfStudentsVoted = 0; // Number of students voted, initialized to 0 
    
    address payable public earliestVoteCastedStudent; // The First student who voted
    
    uint public timeOfEarliestVoteCasted = 0; // Time between the First vote casted by the Earliest voter and the Deadline, initialized to 0
    
    uint public mostVotedStudentVote_Count = 1; // The vote count of the student(s) who got the greatest number of vote tickets. Initialing this variable
                                                // to 1 is to prevent the case where students having 0 vote ticket to become stored in the winningStudent array.
                                                // This is just for a clean and general way of obtaining the true winningStudent array. 


// Initiating the contract

    constructor() public payable{
        professor = msg.sender;     // Professor is the owner of the contract
        scholarship = msg.value;    // The scholarship money from Professor
    }
    
    modifier mustBeProfessor{
        require(msg.sender == professor, "only Professor can do this");
        _;
    }

// (Requirement 2) - At the beginning, Professor will assign 1 vote ticket to each student and therefore setting the student list 
// (in case this contract may be deployed in an external environment)

    function AssignVotes(address payable _student) public mustBeProfessor{

        require(_student != professor, "Professor cannot assign vote ticket to Professor"); // Only students can be assigned vote ticket
        require(students[_student].voteAssigned==false, "student already assigned 1 vote ticket" ); // To avoid duplication of assignment of vote ticket to a student
        students[_student].vote_possession=1; // Only 1 vote ticket to be assigned by Professor to each student
        
        voteAssignedList.push(_student); // The array maintains a list of students assigned 1 vote ticket by the Professor
                                         // and this list is therefore a list of VALID students defined by the Professor
        
        students[_student].voteAssigned=true;   // Setting the student as vote assigned
    }

// (Requirement 1) - The function below is for Professor to initiatialise voting process by setting the Deadline for students to select and vote the winner(s).
// The function gives the choice for the Professor to input the time to deadline, say 10 minutes, in seconds

    function DeadlineToInitialise(uint timeToDeadline) public mustBeProfessor{
        
        require(!isDeadlineSet, "Deadline already set, cannot be resetted again");  // Preventing double setting the deadline by Professor
        require(timeToDeadline > 0, "Has not inputted deadline yet");   // Reminding the Professor to input before pressing button
        deadline = now + timeToDeadline ;   // Setting deadline variable to be the current time + the time to deadline
        isDeadlineSet = true ;  // Setting flag as true after Deadline has been set
    }


// Making sure the time is within the voting period between the setting of Deadline and Deadline itself

    modifier withinDeadlinePeriod{
        require(isDeadlineSet, "Professor has not initialise voting by setting deadline");
        require(deadline > now, "Deadline passed, cannot vote anymore");
        _;
    }


// Restricting voting to only valid candidates ie students in class assigned a vote ticket by the Professor
// (in case this contract may be deployed in an external environment, this is to prevent scholarship to be given to outsiders)

    modifier mustBeValidStudent(address payable toBeIdentified){
        require(students[toBeIdentified].voteAssigned==true, "Cannot vote for an addressee not assigned vote ticket by the Professor, ie this person is not a valid student in class" );
        _;
    }

// (Requirement 3) - The function below allows students to vote for other students with maximum voting chance of 3 times only during the period before Deadline.
// At each voting chance, the voting student can decide to give >= 1 vote tickets to the candidate student as long as he or she has sufficient tickets in possession. 

    function vote(address payable candidate, uint tickets) public withinDeadlinePeriod mustBeValidStudent(candidate){

        require(tickets > 0, "Has not inputted number of tickets"); // Remind students to input number of vote tickets
        require(students[msg.sender].vote_possession >= tickets, "Has not enough or no tickets to vote"); // Only students with sufficient tickets can vote. This also prevents Professor or other outsiders to vote.
        require(candidate != msg.sender, "Students cannot vote for themselves");    // Requirement 4 does not allow students to vote for themselves. 
        require(students[msg.sender].voteCasted_count < 3, "Students cannot vote more than 3 times");   // Requirement 3 condition

        students[msg.sender].vote_possession -= tickets;    // Reducing the voter's tickets by the number of tickets used for this vote chance
        
        // Registering the time of the voter's first voting action
        if (students[msg.sender].voteCasted_count == 0){
            students[msg.sender].timeOfFirstVoteCast = deadline - now ;
        }
        students[msg.sender].voteCasted_count += 1; // Recording how many vote chance has been used by the voter
        
        students[candidate].vote_possession += tickets; // Increasing the tickets of the candidate by the number of tickets received from voter
    }


// Making sure that vote counting, deciding the winner and transferring scholarship can only be done after deadline passed

    modifier mustPassedDeadline{
        require(deadline < now, "deadline has not passed yet, voting is still in progress");
        _;
    }


// (Requirement 4, 5 and 6) - The MAIN function below is to allow the Professor to operate and start vote count, to calculate sufficient voting occurrence or not,
// to determine the first voter, to decide whether there is a winner and to give out scholarship, after Deadline. This main function calls other functions.

    function winningScholar() public mustBeProfessor mustPassedDeadline{   
        
        // The 'for loop' will go through the array of students that have been assigned a vote ticket by Professor, namely all the valid students
        for (uint p = 0; p < voteAssignedList.length; p++){ 
            
            calcNumberOfStudentsVoted(voteAssignedList[p]); // Call the function to count the number of students voted and get the total number of students voted
                                                            // by the end of this 'for loop'
            calcListOfWinningStudents(voteAssignedList[p]); // Call the function to check the number of vote tickets possessed by each student and find out the winning student(s) 
                                                            // with the greatest number of vote tickets by the end of this 'for loop'
            calcEarliestVoteCastedStudent(voteAssignedList[p]); // Call the function to check the time of the first vote by each student and find out the student 
                                                                // who voted first by the end of this 'for loop'
        }
        
        giveScholarship();  // Call the function to decide the winner(s) and transfer scholarship(s) accordingly
    }
 

// (Requirement 5) - The function below allows the counting of how many students have voted. This helps to decide on condition 
// whether more than half of students have not voted.

    function calcNumberOfStudentsVoted(address payable _student) private{

        if (students[_student].voteCasted_count > 0) {
                numberOfStudentsVoted += 1;
        }
    }


// (Vote Count and Requirement 4) - The function below finds out the student(s) with the greatest number of vote tickets and also 
// allowing for Requirement 4 (see below 'else case'). The function records the winning student(s) in the winningStudent array.

    function calcListOfWinningStudents(address payable _student) private{
 
        // The 'if case' here is where the student has voted before, therefore all his or her vote tickets will be counted, including the initial assigned ticket.
        if (students[_student].voteCasted_count > 0){
            
            // To compare the vote tickets possessed by each student with the number of tickets possessed by the currently winning student
            // and to update the maximum number of tickets recorded and revise the winning student record for student with more tickets
            if (students[_student].vote_possession > mostVotedStudentVote_Count) {  
                
                    mostVotedStudentVote_Count = students[_student].vote_possession;
                    delete winningStudent;  // Reseting the winningStudent array 
                    winningStudent.push(_student);
                    
                }else{
                    
                    // This case is for recording students with the same highest number of vote tickets
                    if (students[_student].vote_possession == mostVotedStudentVote_Count) {
                        winningStudent.push(_student);  // No need to reset array this time since there are more than 1 winner in this case
                    }
                }
            }else{
                
                // The 'else case' here is where the parameter voteCasted_out of a student equals 0, which means that the student did not vote for anyone. 
                // Requirement 4 disallows a student to vote himself or herself. 
                // If he/she has not voted for anyone, his/her initial assigned ticket will be invalid after the deadline. 
                // Therefore the vote_possession is reduced by 1 to remove the initial ticket in the count, before performing the comparison and any record update.
                if ((students[_student].vote_possession - 1) > mostVotedStudentVote_Count) {
                
                    mostVotedStudentVote_Count = students[_student].vote_possession - 1;
                    delete winningStudent;
                    winningStudent.push(_student);
                    
                }else{
                    
                    if ((students[_student].vote_possession - 1) == mostVotedStudentVote_Count) {
                        winningStudent.push(_student);
                    }
                }
            }

    }


// (Requirement 5) - The function below identifies and keeps record of the first student who voted i.e. the student who voted at a time furthest from Deadline

    function calcEarliestVoteCastedStudent(address payable _student) private{

        if (students[_student].timeOfFirstVoteCast > timeOfEarliestVoteCasted) {    // Compare the first vote of each student with the prevailing earliest vote recorded
                timeOfEarliestVoteCasted = students[_student].timeOfFirstVoteCast;  // Time of the earliest vote recorded in the timeOfEarliestVoteCasted variable
                earliestVoteCastedStudent = _student;   // Student of the earliest vote cast recorded in the earliestVoteCastedStudent variable
        }
    }   

// (Requirement 5 and 6) - The function below decides the winner(s) of the scholarship(s) and making transfer accordingly. I have added a condition that
// if there is NO voting by any students, no scholarship will be given out.

    function giveScholarship() private{ 
        
        require (0 < numberOfStudentsVoted, "There was NO voting by any student. No scholarship would be given out");
        
        // Requirment 5 conditions the case where more than half of the students have NOT voted, ie less than half of students have voted, 
        // the scholarship will go to the student who voted first. I made use of BASIS POINTS in the comparison of the 'if clause'.
        // The total student population is the set of valid students assigned a single vote ticket by the Professor.
        if ( numberOfStudentsVoted * 10000 / voteAssignedList.length < 5000 ){
            giveToFirstVote(); 
        }else{
            // Otherwise, scholarship will go to the Vote Winner(s)
            giveToVoteWinners();
        }
    }

// (Requirement 5) Case of Invalid Voting - transferring scholarship to the student who first voted

    function giveToFirstVote() private{
        
        delete winningStudent;  // In this case, no winning student by voting
        earliestVoteCastedStudent.transfer(scholarship); // Student of the earliest vote cast recorded gets the scholarship
    } 

// (Requirement 6) Case of Valid Voting - transferring scholarship(s) to the student(s) with the highest number of vote tickets
 
    function giveToVoteWinners() private{
        
        if (winningStudent.length<2){
            
                // Case of a single student winning the most vote tickets
                winningStudent[0].transfer(scholarship);
            }else{
                
                // Case of multiple students with the same number of winning vote tickets, the scholarship will be divided 
                // in equal shares for these winning students
                for (uint i=0; i<winningStudent.length; i++){
                    winningStudent[i].transfer(scholarship/winningStudent.length); 
                }
            }
    } 
}
