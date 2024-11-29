public interface EmployeeMapper {
    List<Employee> displayEmployeeView();
    List<Employee> displayEmployee();
    Integer addEmployee(Employee employee);
    Integer hireEmployee(String username, String id);
    Integer fireEmployee(String username, String id);
}
