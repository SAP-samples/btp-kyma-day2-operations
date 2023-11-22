package dev.kyma.samples.easyfranchise.day2.rest.service;

import java.time.LocalDate;
import java.util.List;

import javax.validation.ValidationException;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
//import javax.validation.constraints.NotNull;
import javax.validation.constraints.NotNull;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import dev.kyma.samples.easyfranchise.day2.jpa.entities.UserLoginInfo;
import dev.kyma.samples.easyfranchise.day2.rest.entities.UserLoginRequestBody;
import dev.kyma.samples.easyfranchise.day2.rest.entities.UserMetric;
import dev.kyma.samples.easyfranchise.day2.services.UserLoginInfoService;

@RestController
@RequestMapping("/")
@Validated
public class UserRestControler {

	@Autowired
	private UserLoginInfoService userLoginInfoService;

	@CrossOrigin //we have to allow CrossOrigin for local testing. Don't allow CrossOrigin for production running applications!! 
	@GetMapping("/user/metric")
	public List<UserMetric> getUserMetric(@RequestParam @NotNull int year,
			@RequestParam @NotNull @Min(1) @Max(12) Integer month) {
		return userLoginInfoService.userMetric(month, year);
	}

	@PutMapping("/user/login")
	public UserLoginInfo mergeUserLogin(@RequestBody UserLoginRequestBody requestBodyInfo) {

		if (requestBodyInfo.getTenantid() == null || requestBodyInfo.getTenantid().length() == 0 || //
				requestBodyInfo.getUser() == null || requestBodyInfo.getUser().length() == 0)
			throw new ValidationException("please provide a valid json with tenantid and user");

		UserLoginInfo info = new UserLoginInfo();
		info.setUser(requestBodyInfo.getUser());
		info.setTenantid(requestBodyInfo.getTenantid());
		info.setMonth(LocalDate.now().getMonthValue());
		info.setYear(LocalDate.now().getYear());

		return userLoginInfoService.mergeUserLogin(info);
	}

}
